import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import axios from "axios";

interface ValidateReceiptData {
  raw: string;
  platform: "ios" | "android";
}

interface ValidateReceiptResponse {
  validated: boolean;
  creditsGranted: number;
}

// Product ID to credits mapping
const PRODUCT_CREDITS: { [key: string]: number } = {
  "credits_5": 5,
  "credits_20": 20,
  "credits_100": 100,
  "sub_monthly_plus": 50,
};

export async function validateReceipt(
  data: ValidateReceiptData,
  context: functions.https.CallableContext
): Promise<ValidateReceiptResponse> {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const uid = context.auth.uid;
  const { raw, platform } = data;

  try {
    let validated = false;
    let productId = "";
    let transactionId = "";

    // Validate with store
    if (platform === "ios") {
      const result = await validateAppleReceipt(raw);
      validated = result.validated;
      productId = result.productId;
      transactionId = result.transactionId;
    } else if (platform === "android") {
      const result = await validateGoogleReceipt(raw);
      validated = result.validated;
      productId = result.productId;
      transactionId = result.transactionId;
    }

    if (!validated) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Receipt validation failed"
      );
    }

    // Check if receipt already processed (idempotency)
    const existingReceipt = await admin
      .firestore()
      .collection("receipts")
      .where("uid", "==", uid)
      .where("transactionId", "==", transactionId)
      .limit(1)
      .get();

    if (!existingReceipt.empty) {
      functions.logger.info(`Receipt already processed: ${transactionId}`);
      const receipt = existingReceipt.docs[0].data();
      return {
        validated: true,
        creditsGranted: receipt.creditsGranted || 0,
      };
    }

    // Determine credits to grant
    const creditsGranted = PRODUCT_CREDITS[productId] || 0;

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

      // Create receipt document
      const receiptRef = admin.firestore().collection("receipts").doc();
      transaction.set(receiptRef, {
        uid,
        store: platform === "ios" ? "appstore" : "play",
        productId,
        type: productId.startsWith("sub_") ? "subscription" : "consumable",
        raw,
        validated: true,
        creditsGranted,
        transactionId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user credits
      transaction.update(userRef, {
        credits: currentCredits + creditsGranted,
      });
    });

    functions.logger.info(
      `Receipt validated for ${uid}: ${creditsGranted} credits granted`
    );

    return {
      validated: true,
      creditsGranted,
    };
  } catch (error) {
    functions.logger.error("Receipt validation error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Receipt validation failed"
    );
  }
}

async function validateAppleReceipt(receiptData: string): Promise<{
  validated: boolean;
  productId: string;
  transactionId: string;
}> {
  // In production, use Apple's verification endpoint
  // For sandbox: https://sandbox.itunes.apple.com/verifyReceipt
  // For production: https://buy.itunes.apple.com/verifyReceipt

  const url = "https://sandbox.itunes.apple.com/verifyReceipt";
  const password = functions.config().apple?.shared_secret || "";

  try {
    const response = await axios.post(url, {
      "receipt-data": receiptData,
      password,
    });

    const { status, receipt } = response.data;

    if (status === 0) {
      // Valid receipt
      const inApp = receipt.in_app?.[0];
      return {
        validated: true,
        productId: inApp?.product_id || "",
        transactionId: inApp?.transaction_id || "",
      };
    }

    return {
      validated: false,
      productId: "",
      transactionId: "",
    };
  } catch (error) {
    functions.logger.error("Apple receipt validation error:", error);
    return {
      validated: false,
      productId: "",
      transactionId: "",
    };
  }
}

async function validateGoogleReceipt(receiptData: string): Promise<{
  validated: boolean;
  productId: string;
  transactionId: string;
}> {
  // In production, use Google Play Developer API
  // Requires setup of service account and Google Play API

  try {
    const receipt = JSON.parse(receiptData);
    // Simplified validation - in production, verify with Google Play API
    return {
      validated: true,
      productId: receipt.productId || "",
      transactionId: receipt.purchaseToken || "",
    };
  } catch (error) {
    functions.logger.error("Google receipt validation error:", error);
    return {
      validated: false,
      productId: "",
      transactionId: "",
    };
  }
}
