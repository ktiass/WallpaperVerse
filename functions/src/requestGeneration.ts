import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { spendCredits } from "./spendCredits";

interface RequestGenerationData {
  prompt: string;
  aspect: "9:16" | "1:1" | "2:3";
  stylePreset?: string;
  chromatic?: number;
}

interface RequestGenerationResponse {
  genId: string;
}

const ASPECT_RATIOS: { [key: string]: { width: number; height: number } } = {
  "9:16": { width: 1080, height: 1920 },
  "1:1": { width: 1024, height: 1024 },
  "2:3": { width: 1024, height: 1536 },
};

export async function requestGeneration(
  data: RequestGenerationData,
  context: functions.https.CallableContext
): Promise<RequestGenerationResponse> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { prompt, aspect, stylePreset, chromatic } = data;

  // Validate input
  if (!prompt || prompt.trim().length < 3) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Prompt must be at least 3 characters"
    );
  }

  if (!aspect || !ASPECT_RATIOS[aspect]) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid aspect ratio"
    );
  }

  try {
    // Calculate credit cost based on resolution
    const dimensions = ASPECT_RATIOS[aspect];
    const pixels = dimensions.width * dimensions.height;
    let creditCost = 1;

    if (pixels > 1024 * 1024 && pixels <= 1024 * 2048) {
      creditCost = 2;
    } else if (pixels > 1024 * 2048) {
      creditCost = 3;
    }

    // Check and spend credits
    await spendCredits(
      {
        amount: creditCost,
        reason: "generation",
      },
      context
    );

    // Create generation document
    const genRef = admin.firestore().collection("generations").doc();
    const genId = genRef.id;

    await genRef.set({
      uid,
      prompt: prompt.trim(),
      style: {
        aspect,
        stylePreset: stylePreset || "realistic",
        chromatic: chromatic || 1.0,
      },
      status: "queued",
      creditCost,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(
      `Generation requested: ${genId} by ${uid} - ${creditCost} credits`
    );

    // In production, enqueue job to task queue
    // For now, the scheduled worker will pick it up

    return {
      genId,
    };
  } catch (error) {
    functions.logger.error("Request generation error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      "Failed to request generation"
    );
  }
}
