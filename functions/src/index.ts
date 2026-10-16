import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { initializeApp } from "firebase-admin/app";
import { GoogleGenerativeAI } from "@google/generative-ai";

initializeApp();

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
}

/**
 * Trusted backend callable for Recallr Gemini AI grounded answer generation.
 * Enforces:
 *  1. User authentication (Firebase Auth JWT).
 *  2. App Check validation (configurable per environment).
 *  3. Prompt character boundaries & model whitelist.
 *  4. Secure server-side API key retrieval via Google Cloud Secret Manager.
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

    // 3. Retrieve API Key securely from Secret Manager (or fallback to env in local emulator)
    const apiKey = geminiApiKey.value() || process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey.trim().length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "Server configuration error: Gemini API secret is not configured in Secret Manager."
      );
    }

    // 4. Invoke Gemini via official Node.js SDK
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
