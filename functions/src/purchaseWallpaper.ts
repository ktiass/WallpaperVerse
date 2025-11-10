import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { spendCredits } from "./spendCredits";

interface PurchaseWallpaperData {
  wallpaperId: string;
}

interface PurchaseWallpaperResponse {
  owned: boolean;
}

export async function purchaseWallpaper(
  data: PurchaseWallpaperData,
  context: functions.https.CallableContext
): Promise<PurchaseWallpaperResponse> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { wallpaperId } = data;

  if (!wallpaperId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Wallpaper ID is required"
    );
  }

  try {
    // Get wallpaper document
    const wallpaperDoc = await admin
      .firestore()
      .collection("wallpapers")
      .doc(wallpaperId)
      .get();

    if (!wallpaperDoc.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Wallpaper not found"
      );
    }

    const wallpaper = wallpaperDoc.data();
    const price = wallpaper?.price || 1;

    // Check if already owned
    const existingOwnership = await admin
      .firestore()
      .collection("user_ownership")
      .doc(uid)
      .collection("items")
      .where("refId", "==", wallpaperId)
      .limit(1)
      .get();

    if (!existingOwnership.empty) {
      functions.logger.info(`Wallpaper already owned: ${wallpaperId}`);
      return { owned: true };
    }

    // Spend credits
    await spendCredits(
      {
        amount: price,
        reason: "unlock",
        refId: wallpaperId,
      },
      context
    );

    // Use transaction for atomicity
    await admin.firestore().runTransaction(async (transaction) => {
      // Create ownership record
      const ownershipRef = admin
        .firestore()
        .collection("user_ownership")
        .doc(uid)
        .collection("items")
        .doc();

      transaction.set(ownershipRef, {
        type: "wallpaper",
        refId: wallpaperId,
        source: "purchase",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Increment sales counter
      const wallpaperRef = admin
        .firestore()
        .collection("wallpapers")
        .doc(wallpaperId);

      transaction.update(wallpaperRef, {
        sales: admin.firestore.FieldValue.increment(1),
      });
    });

    functions.logger.info(`Wallpaper purchased: ${wallpaperId} by ${uid}`);

    return { owned: true };
  } catch (error) {
    functions.logger.error("Purchase wallpaper error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      "Failed to purchase wallpaper"
    );
  }
}
