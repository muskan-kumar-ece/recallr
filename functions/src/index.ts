import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";
import { GoogleGenerativeAI } from "@google/generative-ai";

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

    // 3. Verify user credit quota before invoking upstream AI
    const subDocRef = db.collection("users").doc(uid).collection("subscription").doc("current");
    const subSnap = await subDocRef.get();

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
      await subDocRef.set(subData, { merge: true });
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

      // 6. Atomically deduct credit & log transaction ledger
      let remainingCreditsAfter = totalAvailable - 1;
      try {
        await db.runTransaction(async (tx) => {
          const freshSnap = await tx.get(subDocRef);
          const freshData = freshSnap.data() || subData;
          const freshMonthlyTotal = typeof freshData.monthlyCreditsTotal === "number" ? freshData.monthlyCreditsTotal : 20;
          const freshMonthlyUsed = typeof freshData.monthlyCreditsUsed === "number" ? freshData.monthlyCreditsUsed : 0;
          const freshPurchased = typeof freshData.purchasedCredits === "number" ? freshData.purchasedCredits : 0;

          let newMonthlyUsed = freshMonthlyUsed;
          let newPurchased = freshPurchased;

          if (freshMonthlyTotal - freshMonthlyUsed > 0) {
            newMonthlyUsed += 1;
          } else if (freshPurchased > 0) {
            newPurchased -= 1;
          }

          remainingCreditsAfter = Math.max(0, (freshMonthlyTotal - newMonthlyUsed) + newPurchased);

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
              promptTokens: usage?.promptTokenCount ?? null,
              candidateTokens: usage?.candidatesTokenCount ?? null,
              model: modelName,
            },
          });
        });
      } catch (ledgerErr) {
        // Log ledger failure but do not crash user response
        console.error("Failed to commit credit ledger deduction:", ledgerErr);
      }

      return {
        text,
        finishReason,
        promptTokens: usage?.promptTokenCount ?? null,
        candidateTokens: usage?.candidatesTokenCount ?? null,
        remainingCredits: remainingCreditsAfter,
      };
    } catch (err: any) {
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

      throw new HttpsError("internal", `Gemini generation failed: ${err?.message || "unknown error"}`);
    }
  }
);
