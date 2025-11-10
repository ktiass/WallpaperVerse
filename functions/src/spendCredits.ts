import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

interface SpendCreditsData {
  amount: number;
  reason: "generation" | "unlock" | "download";
  refId?: string;
}

interface SpendCreditsResponse {
  ok: boolean;
  authToken: string;
}

export async function spendCredits(
  data: SpendCreditsData,
  context: functions.https.CallableContext
): Promise<SpendCreditsResponse> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { amount, reason, refId } = data;

  // Validate input
  if (!amount || amount <= 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Amount must be greater than 0"
    );
  }

  if (!reason) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Reason is required"
    );
  }

  try {
    // Use transaction to ensure atomicity
    await admin.firestore().runTransaction(async (transaction) => {
      const userRef = admin.firestore().collection("users").doc(uid);
      const userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "User document not found"
        );
      }

      const currentCredits = userDoc.data()?.credits || 0;

      if (currentCredits < amount) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Insufficient credits"
        );
      }

      // Deduct credits
      transaction.update(userRef, {
        credits: currentCredits - amount,
      });

      // Create audit log
      const auditRef = admin.firestore().collection("credit_audit").doc();
      transaction.set(auditRef, {
        uid,
        amount: -amount,
        reason,
        refId: refId || null,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Generate auth token (simplified - in production use proper JWT)
    const authToken = Buffer.from(
      `${uid}:${Date.now()}:${reason}:${refId || ""}`
    ).toString("base64");

    functions.logger.info(
      `Credits spent: ${uid} - ${amount} credits for ${reason}`
    );

    return {
      ok: true,
      authToken,
    };
  } catch (error) {
    functions.logger.error("Spend credits error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "Failed to spend credits");
  }
}
