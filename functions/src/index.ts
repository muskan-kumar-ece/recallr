import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";
import * as crypto from "crypto";

initializeApp();

const db = getFirestore();

// Secret Manager binding for Gemini API Key
const geminiApiKey = defineSecret("GEMINI_API_KEY");

// Allowed models whitelist
const ALLOWED_MODELS = new Set([
  "gemini-1.5-flash",
  "gemini-1.5-pro",
  "gemini-2.0-flash",
]);

interface GenerateGroundedAnswerRequest {
  prompt: string;
  systemInstruction?: string;
  model?: string;
  temperature?: number;
  maxOutputTokens?: number;
}

interface GenerateGroundedAnswerResponse {
  text: string;
  finishReason: string | null;
  promptTokens: number | null;
  candidateTokens: number | null;
  remainingCredits?: number;
}

/**
 * Trusted backend callable for Recallr Gemini AI grounded answer generation.
 * Enforces:
 *  1. User authentication (Firebase Auth JWT).
 *  2. Server-side AI Credit Quota & Subscription validation.
 *  3. Prompt character boundaries & model whitelist.
 *  4. Secure server-side API key retrieval via Google Cloud Secret Manager.
 *  5. Atomic credit deduction & audit ledger logging.
 */
export const generateGroundedAnswer = onCall(
  {
    secrets: [geminiApiKey],
    enforceAppCheck: false, // Set to true once App Check enforcement is activated in production console
    timeoutSeconds: 30,
    memory: "256MiB",
    cors: false,
  },
  async (request): Promise<GenerateGroundedAnswerResponse> => {
    // 1. Authenticate user - reject unauthenticated requests
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Request must be authenticated with a valid Firebase user session."
      );
    }

    const uid = request.auth.uid;

    // 2. Validate input payload
    const data = request.data as Partial<GenerateGroundedAnswerRequest>;
    if (!data || typeof data.prompt !== "string" || data.prompt.trim().length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "The 'prompt' field must be a non-empty string."
      );
    }

    const prompt = data.prompt.trim();
    if (prompt.length > 25000) {
      throw new HttpsError(
        "invalid-argument",
        `Prompt exceeds maximum allowed length of 25,000 characters (received ${prompt.length}).`
      );
    }

    let systemInstruction = "";
    if (data.systemInstruction && typeof data.systemInstruction === "string") {
      if (data.systemInstruction.length > 10000) {
        throw new HttpsError(
          "invalid-argument",
          "System instruction exceeds maximum allowed length of 10,000 characters."
        );
      }
      systemInstruction = data.systemInstruction.trim();
    }

    const modelName = data.model && ALLOWED_MODELS.has(data.model)
      ? data.model
      : "gemini-1.5-flash";

    const temperature = typeof data.temperature === "number"
      ? Math.max(0.0, Math.min(2.0, data.temperature))
      : 0.2;

    const maxOutputTokens = typeof data.maxOutputTokens === "number"
      ? Math.max(16, Math.min(4096, data.maxOutputTokens))
      : 1024;

    // 3. Atomically check and reserve user credit BEFORE invoking upstream AI (Anti-concurrency overdraft)
    const subDocRef = db.collection("users").doc(uid).collection("subscription").doc("current");
    let remainingCreditsAfter = 0;
    let deductedFrom: "monthly" | "purchased" = "monthly";

    await db.runTransaction(async (tx) => {
      const subSnap = await tx.get(subDocRef);
      let subData = subSnap.data();
      if (!subSnap.exists || !subData) {
        // Lazily initialize default Starter subscription
        const now = new Date();
        const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
        subData = {
          tier: "starter",
          status: "active",
          currency: "INR",
          storageLimitBytes: 104857600, // 100 MB
          storageUsedBytes: 0,
          monthlyCreditsTotal: 20,
          monthlyCreditsUsed: 0,
          purchasedCredits: 0,
          currentPeriodStart: Timestamp.fromDate(now),
          currentPeriodEnd: Timestamp.fromDate(periodEnd),
          billingProvider: "mock",
          updatedAt: FieldValue.serverTimestamp(),
        };
        tx.set(subDocRef, subData);
      }

      const monthlyTotal = typeof subData.monthlyCreditsTotal === "number" ? subData.monthlyCreditsTotal : 20;
      const monthlyUsed = typeof subData.monthlyCreditsUsed === "number" ? subData.monthlyCreditsUsed : 0;
      const purchased = typeof subData.purchasedCredits === "number" ? subData.purchasedCredits : 0;
      const availableMonthly = Math.max(0, monthlyTotal - monthlyUsed);
      const totalAvailable = availableMonthly + purchased;

      if (totalAvailable < 1) {
        throw new HttpsError(
          "resource-exhausted",
          "AI credits exhausted. Top up 150 credits for ₹19 or upgrade to Pro."
        );
      }

      let newMonthlyUsed = monthlyUsed;
      let newPurchased = purchased;
      if (availableMonthly > 0) {
        newMonthlyUsed += 1;
        deductedFrom = "monthly";
      } else {
        newPurchased -= 1;
        deductedFrom = "purchased";
      }

      remainingCreditsAfter = Math.max(0, (monthlyTotal - newMonthlyUsed) + newPurchased);

      tx.update(subDocRef, {
        monthlyCreditsUsed: newMonthlyUsed,
        purchasedCredits: newPurchased,
        updatedAt: FieldValue.serverTimestamp(),
      });

      const ledgerRef = db.collection("users").doc(uid).collection("credit_ledger").doc();
      tx.set(ledgerRef, {
        id: ledgerRef.id,
        timestamp: FieldValue.serverTimestamp(),
        type: "debit",
        amount: 1,
        reason: "ask_query",
        metadata: {
          model: modelName,
        },
      });
    });

    // 4. Retrieve API Key securely from Secret Manager (or fallback to env in local emulator)
    const apiKey = geminiApiKey.value() || process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey.trim().length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Server configuration error: Gemini API secret is not configured in Secret Manager."
      );
    }

    // 5. Invoke Gemini via official Node.js SDK
    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: modelName,
        generationConfig: {
          temperature,
          maxOutputTokens,
          responseMimeType: "application/json",
        },
        systemInstruction: systemInstruction
          ? {
              role: "system",
              parts: [{ text: systemInstruction }],
            }
          : undefined,
      });

      const result = await model.generateContent(prompt);
      const response = result.response;
      const text = response.text()?.trim() ?? "";

      if (text.length === 0) {
        throw new HttpsError(
          "internal",
          "Received empty generation response from Gemini."
        );
      }

      const candidate = response.candidates?.[0];
      const finishReason = candidate?.finishReason ?? null;
      const usage = response.usageMetadata;

      return {
        text,
        finishReason,
        promptTokens: usage?.promptTokenCount ?? null,
        candidateTokens: usage?.candidatesTokenCount ?? null,
        remainingCredits: remainingCreditsAfter,
      };
    } catch (err: any) {
      // Compensating transaction: Refund deducted credit if Gemini generation failed
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(subDocRef);
          if (snap.exists) {
            const data = snap.data() || {};
            if (deductedFrom === "monthly") {
              const used = typeof data.monthlyCreditsUsed === "number" ? data.monthlyCreditsUsed : 1;
              tx.update(subDocRef, {
                monthlyCreditsUsed: Math.max(0, used - 1),
                updatedAt: FieldValue.serverTimestamp(),
              });
            } else {
              const currentPurchased = typeof data.purchasedCredits === "number" ? data.purchasedCredits : 0;
              tx.update(subDocRef, {
                purchasedCredits: currentPurchased + 1,
                updatedAt: FieldValue.serverTimestamp(),
              });
            }
            const refundLedgerRef = db.collection("users").doc(uid).collection("credit_ledger").doc();
            tx.set(refundLedgerRef, {
              id: refundLedgerRef.id,
              timestamp: FieldValue.serverTimestamp(),
              type: "credit",
              amount: 1,
              reason: "generation_failure_refund",
              metadata: {
                error: err?.message || String(err),
              },
            });
          }
        });
      } catch (refundErr) {
        console.error("Credit refund transaction failed:", refundErr);
      }

      if (err instanceof HttpsError) {
        throw err;
      }

      const errStr = (err?.message || err?.toString() || "").toLowerCase();

      // Map upstream rate limits
      if (errStr.includes("429") || errStr.includes("quota") || errStr.includes("resource_exhausted")) {
        throw new HttpsError("resource-exhausted", "Upstream AI rate limit exceeded. Please try again later.");
      }

      // Map upstream auth / permission errors
      if (errStr.includes("api_key") || errStr.includes("permission_denied") || errStr.includes("403") || errStr.includes("401")) {
        throw new HttpsError("internal", "AI service authorization failure.");
      }

      // Map upstream bad requests
      if (errStr.includes("invalid_argument") || errStr.includes("400")) {
        throw new HttpsError("invalid-argument", "The model rejected the prompt format.");
      }

      console.error("Gemini invocation failed:", err);
      throw new HttpsError("internal", `Gemini generation failed: ${err?.message || "unknown error"}`);
    }
  }
);

interface CatalogItem {
  id: string;
  name: string;
  type: "credit_pack" | "subscription_tier";
  amountPaise: number;
  credits?: number;
  tier?: string;
  storageLimitBytes?: number;
}

const CATALOG: Record<string, CatalogItem> = {
  // Micro Credit Top-Up Packs (One-time, non-expiring)
  pack_150: {
    id: "pack_150",
    name: "150 AI Credits",
    type: "credit_pack",
    amountPaise: 1900, // ₹19.00
    credits: 150,
  },
  credit_pack_150: {
    id: "credit_pack_150",
    name: "150 AI Credits",
    type: "credit_pack",
    amountPaise: 1900,
    credits: 150,
  },
  pack_500: {
    id: "pack_500",
    name: "500 AI Credits",
    type: "credit_pack",
    amountPaise: 4900, // ₹49.00
    credits: 500,
  },
  credit_pack_500: {
    id: "credit_pack_500",
    name: "500 AI Credits",
    type: "credit_pack",
    amountPaise: 4900,
    credits: 500,
  },
  pack_1500: {
    id: "pack_1500",
    name: "1,500 AI Credits",
    type: "credit_pack",
    amountPaise: 12900, // ₹129.00
    credits: 1500,
  },
  credit_pack_1500: {
    id: "credit_pack_1500",
    name: "1,500 AI Credits",
    type: "credit_pack",
    amountPaise: 12900,
    credits: 1500,
  },
  // Tiers (Monthly / Annual)
  tier_pro_monthly: {
    id: "tier_pro_monthly",
    name: "Pro Networker (Monthly)",
    type: "subscription_tier",
    amountPaise: 4900, // ₹49.00
    tier: "pro",
    credits: 250,
    storageLimitBytes: 1610612736, // 1.5 GB
  },
  tier_pro_annual: {
    id: "tier_pro_annual",
    name: "Pro Networker (Annual)",
    type: "subscription_tier",
    amountPaise: 39900, // ₹399.00
    tier: "pro",
    credits: 250,
    storageLimitBytes: 1610612736, // 1.5 GB
  },
  tier_executive_monthly: {
    id: "tier_executive_monthly",
    name: "Executive (Monthly)",
    type: "subscription_tier",
    amountPaise: 14900, // ₹149.00
    tier: "executive",
    credits: 1000,
    storageLimitBytes: 6442450944, // 6.0 GB
  },
  tier_executive_annual: {
    id: "tier_executive_annual",
    name: "Executive (Annual)",
    type: "subscription_tier",
    amountPaise: 129900, // ₹1,299.00
    tier: "executive",
    credits: 1000,
    storageLimitBytes: 6442450944, // 6.0 GB
  },
};

/**
 * Creates a verified Razorpay order server-side.
 */
export const createRazorpayOrder = onCall(
  {
    timeoutSeconds: 15,
    memory: "256MiB",
    cors: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated to create a payment order.");
    }

    const { catalogId } = request.data || {};
    if (!catalogId || !CATALOG[catalogId]) {
      throw new HttpsError("invalid-argument", `Invalid catalog item: ${catalogId}`);
    }

    const item = CATALOG[catalogId];
    const uid = request.auth.uid;

    const keyId = process.env.RAZORPAY_KEY_ID;
    const secret = process.env.RAZORPAY_KEY_SECRET;

    // If real Razorpay keys are configured, call Razorpay Orders API
    if (keyId && secret && keyId.startsWith("rzp_")) {
      try {
        const authHeader = Buffer.from(`${keyId}:${secret}`).toString("base64");
        const resp = await fetch("https://api.razorpay.com/v1/orders", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Basic ${authHeader}`,
          },
          body: JSON.stringify({
            amount: item.amountPaise,
            currency: "INR",
            receipt: `rcpt_${uid.substring(0, 8)}_${Date.now()}`,
            notes: {
              userId: uid,
              catalogId: item.id,
              name: item.name,
            },
          }),
        });

        if (!resp.ok) {
          const errText = await resp.text();
          console.error("Razorpay order creation upstream failed:", errText);
          throw new HttpsError("internal", `Payment gateway error: ${resp.status}`);
        }

        const data: any = await resp.json();
        return {
          orderId: data.id,
          amount: data.amount,
          currency: data.currency,
          keyId: keyId,
          catalogId: item.id,
          name: item.name,
          isTestMode: keyId.includes("test"),
        };
      } catch (err: any) {
        if (err instanceof HttpsError) throw err;
        console.error("Razorpay order fetch exception:", err);
        throw new HttpsError("internal", "Failed to contact Razorpay payment gateway.");
      }
    }

    // Fallback: Safe deterministic test mode order when keys are pending setup
    const testOrderId = `order_test_${Date.now()}`;
    return {
      orderId: testOrderId,
      amount: item.amountPaise,
      currency: "INR",
      keyId: "rzp_test_placeholder",
      catalogId: item.id,
      name: item.name,
      isTestMode: true,
    };
  }
);

/**
 * Cryptographically verifies Razorpay payment and atomically unlocks credits or tier.
 */
export const verifyRazorpayPayment = onCall(
  {
    timeoutSeconds: 15,
    memory: "256MiB",
    cors: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated to verify payments.");
    }

    const { orderId, paymentId, signature, catalogId } = request.data || {};
    if (!orderId || !paymentId || !catalogId || !CATALOG[catalogId]) {
      throw new HttpsError("invalid-argument", "Missing or invalid payment verification parameters.");
    }

    const item = CATALOG[catalogId];
    const uid = request.auth.uid;

    const secret = process.env.RAZORPAY_KEY_SECRET;
    const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

    // 1. Mandatory server-side cryptographic signature verification
    if (!secret && !isEmulator) {
      console.error("RAZORPAY_KEY_SECRET is not configured on the server.");
      throw new HttpsError("failed-precondition", "Server payment configuration error.");
    }

    if (secret) {
      if (!signature) {
        throw new HttpsError("invalid-argument", "Payment signature is required.");
      }
      const expectedSig = crypto
        .createHmac("sha256", secret)
        .update(`${orderId}|${paymentId}`)
        .digest("hex");

      if (expectedSig !== signature) {
        console.error("Signature mismatch. Expected:", expectedSig, "Got:", signature);
        throw new HttpsError("permission-denied", "Cryptographic payment verification failed.");
      }
    }

    // 2. Atomic update with payment idempotency & replay protection
    const paymentLockRef = db.collection("processed_payments").doc(paymentId);
    const subDocRef = db.collection("users").doc(uid).collection("subscription").doc("current");
    const ledgerRef = db.collection("users").doc(uid).collection("credit_ledger").doc();

    let updatedCredits = 0;
    let updatedTier = "starter";

    await db.runTransaction(async (tx) => {
      // Replay defense: verify payment has not been processed previously
      const paymentLockSnap = await tx.get(paymentLockRef);
      if (paymentLockSnap.exists) {
        throw new HttpsError("already-exists", "This payment has already been verified and processed.");
      }

      // Atomically record payment lock
      tx.set(paymentLockRef, {
        paymentId,
        orderId,
        uid,
        catalogId: item.id,
        amountPaise: item.amountPaise,
        processedAt: FieldValue.serverTimestamp(),
      });

      const subSnap = await tx.get(subDocRef);
      const subData = subSnap.exists ? subSnap.data() || {} : {};

      const currentMonthlyUsed = subData.monthlyCreditsUsed ?? 0;
      const currentPurchased = subData.purchasedCredits ?? 0;
      const currentMonthlyTotal = subData.monthlyCreditsTotal ?? 20;

      if (item.type === "credit_pack") {
        const newPurchased = currentPurchased + (item.credits ?? 0);
        tx.set(
          subDocRef,
          {
            purchasedCredits: newPurchased,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        updatedCredits = Math.max(0, currentMonthlyTotal - currentMonthlyUsed) + newPurchased;
        updatedTier = subData.tier ?? "starter";
      } else {
        // subscription_tier
        const isAnnual = item.id.endsWith("_annual");
        const days = isAnnual ? 365 : 30;
        const periodEnd = new Date(Date.now() + days * 24 * 60 * 60 * 1000);

        tx.set(
          subDocRef,
          {
            tier: item.tier,
            status: "active",
            monthlyCreditsTotal: item.credits ?? 250,
            storageLimitBytes: item.storageLimitBytes ?? 1610612736,
            currentPeriodStart: FieldValue.serverTimestamp(),
            currentPeriodEnd: Timestamp.fromDate(periodEnd),
            cancelAtPeriodEnd: false,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
        updatedCredits = (item.credits ?? 250) + currentPurchased;
        updatedTier = item.tier ?? "pro";
      }

      // Record to immutable credit ledger
      tx.set(ledgerRef, {
        id: ledgerRef.id,
        timestamp: FieldValue.serverTimestamp(),
        type: "credit",
        amount: item.credits ?? 0,
        reason: item.type === "credit_pack" ? "pack_purchase" : "tier_upgrade",
        metadata: {
          catalogId: item.id,
          amountPaidPaise: item.amountPaise,
          paymentId: paymentId,
          orderId: orderId,
        },
      });
    });

    return {
      success: true,
      catalogId: item.id,
      tier: updatedTier,
      totalCredits: updatedCredits,
      message: `Successfully fulfilled ${item.name}!`,
    };
  }
);
