import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import { validateReceipt } from "./validateReceipt";
import { spendCredits } from "./spendCredits";
import { requestGeneration } from "./requestGeneration";
import { unlockGenerated } from "./unlockGenerated";
import { purchaseWallpaper } from "./purchaseWallpaper";
import { generationWorker } from "./generationWorker";

admin.initializeApp();

// Callable functions
export const validateReceiptCallable = functions.https.onCall(validateReceipt);
export const spendCreditsCallable = functions.https.onCall(spendCredits);
export const requestGenerationCallable = functions.https.onCall(requestGeneration);
export const unlockGeneratedCallable = functions.https.onCall(unlockGenerated);
export const purchaseWallpaperCallable = functions.https.onCall(purchaseWallpaper);

// Background worker
export const generationWorkerHttp = functions.https.onRequest(generationWorker);

// Scheduled worker (runs every minute to process queued generations)
export const generationWorkerScheduled = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async () => {
    // This would trigger the generation worker
    // In production, use a proper task queue
    functions.logger.info("Generation worker scheduled run");
  });
