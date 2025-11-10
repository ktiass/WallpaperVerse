import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

interface UnlockGeneratedData {
  genId: string;
}

interface UnlockGeneratedResponse {
  owned: boolean;
}

export async function unlockGenerated(
  data: UnlockGeneratedData,
  context: functions.https.CallableContext
): Promise<UnlockGeneratedResponse> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { genId } = data;

  if (!genId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Generation ID is required"
    );
  }

  try {
    // Get generation document
    const genDoc = await admin
      .firestore()
      .collection("generations")
      .doc(genId)
      .get();

    if (!genDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Generation not found"
      );
    }

    const generation = genDoc.data();

    // Verify ownership
    if (generation?.uid !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You don't own this generation"
      );
    }

    // Check if generation is completed
    if (generation?.status !== "succeeded") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Generation is not completed"
      );
    }

    // Check if already owned
    const existingOwnership = await admin
      .firestore()
      .collection("user_ownership")
      .doc(uid)
      .collection("items")
      .where("refId", "==", genId)
      .limit(1)
      .get();

    if (!existingOwnership.empty) {
      functions.logger.info(`Generation already owned: ${genId}`);
      return { owned: true };
    }

    // Create ownership record (no additional credits needed as already paid)
    await admin
      .firestore()
      .collection("user_ownership")
      .doc(uid)
      .collection("items")
      .add({
        type: "generation",
        refId: genId,
        source: "purchase",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    functions.logger.info(`Generation unlocked: ${genId} for ${uid}`);

    return { owned: true };
  } catch (error) {
    functions.logger.error("Unlock generated error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      "Failed to unlock generation"
    );
  }
}
