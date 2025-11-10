import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import axios from "axios";
import * as sharp from "sharp";

export async function generationWorker(
  req: functions.https.Request,
  res: functions.Response
): Promise<void> {
  try {
    // Get queued generations
    const snapshot = await admin
      .firestore()
      .collection("generations")
      .where("status", "==", "queued")
      .orderBy("createdAt", "asc")
      .limit(5)
      .get();

    if (snapshot.empty) {
      res.status(200).send({ message: "No queued generations" });
      return;
    }

    const promises = snapshot.docs.map((doc) => processGeneration(doc.id, doc.data()));

    await Promise.all(promises);

    res.status(200).send({
      message: "Processing complete",
      processed: snapshot.docs.length,
    });
  } catch (error) {
    functions.logger.error("Generation worker error:", error);
    res.status(500).send({ error: "Worker failed" });
  }
}

async function processGeneration(genId: string, data: admin.firestore.DocumentData): Promise<void> {
  try {
    // Update status to running
    await admin.firestore().collection("generations").doc(genId).update({
      status: "running",
    });

    // Get AI provider settings from config
    const providerType = functions.config().ai?.provider || "stability";
    const apiKey = functions.config().ai?.api_key || "";

    if (!apiKey) {
      throw new Error("AI provider API key not configured");
    }

    // Generate image using AI provider
    const { prompt, style } = data;
    const dimensions = getAspectDimensions(style.aspect);

    const imageUrl = await generateWithAI(
      providerType,
      apiKey,
      prompt,
      dimensions.width,
      dimensions.height,
      style.stylePreset
    );

    // Download and save image to Storage
    const storagePath = `protected/users/${data.uid}/generations/${genId}/full.jpg`;
    const thumbnailPath = `protected/users/${data.uid}/generations/${genId}/thumb.jpg`;

    await saveImageToStorage(imageUrl, storagePath);

    // Create watermarked thumbnail
    await createWatermarkedThumbnail(storagePath, thumbnailPath, genId);

    // Update generation document
    await admin.firestore().collection("generations").doc(genId).update({
      status: "succeeded",
      storagePath,
      thumbnailPath,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info(`Generation completed: ${genId}`);
  } catch (error) {
    functions.logger.error(`Generation failed: ${genId}`, error);

    await admin.firestore().collection("generations").doc(genId).update({
      status: "failed",
      error: error instanceof Error ? error.message : "Unknown error",
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

function getAspectDimensions(aspect: string): { width: number; height: number } {
  const ratios: { [key: string]: { width: number; height: number } } = {
    "9:16": { width: 1080, height: 1920 },
    "1:1": { width: 1024, height: 1024 },
    "2:3": { width: 1024, height: 1536 },
  };

  return ratios[aspect] || ratios["9:16"];
}

async function generateWithAI(
  providerType: string,
  apiKey: string,
  prompt: string,
  width: number,
  height: number,
  stylePreset: string
): Promise<string> {
  if (providerType === "stability") {
    return generateWithStability(apiKey, prompt, width, height, stylePreset);
  } else if (providerType === "openai") {
    return generateWithOpenAI(apiKey, prompt, width, height);
  }

  throw new Error(`Unknown AI provider: ${providerType}`);
}

async function generateWithStability(
  apiKey: string,
  prompt: string,
  width: number,
  height: number,
  stylePreset: string
): Promise<string> {
  const response = await axios.post(
    "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image",
    {
      text_prompts: [{ text: prompt, weight: 1 }],
      cfg_scale: 7,
      width,
      height,
      samples: 1,
      steps: 30,
      style_preset: stylePreset,
    },
    {
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  const artifacts = response.data.artifacts;
  if (!artifacts || artifacts.length === 0) {
    throw new Error("No image generated");
  }

  // Return base64 data URL
  return `data:image/png;base64,${artifacts[0].base64}`;
}

async function generateWithOpenAI(
  apiKey: string,
  prompt: string,
  width: number,
  height: number
): Promise<string> {
  // Determine size (DALL-E has specific sizes)
  let size = "1024x1024";
  if (width === 1024 && height === 1792) {
    size = "1024x1792";
  } else if (width === 1792 && height === 1024) {
    size = "1792x1024";
  }

  const response = await axios.post(
    "https://api.openai.com/v1/images/generations",
    {
      model: "dall-e-3",
      prompt,
      n: 1,
      size,
      quality: "hd",
    },
    {
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    }
  );

  const data = response.data.data;
  if (!data || data.length === 0) {
    throw new Error("No image generated");
  }

  return data[0].url;
}

async function saveImageToStorage(imageUrl: string, storagePath: string): Promise<void> {
  // Download image
  let imageBuffer: Buffer;

  if (imageUrl.startsWith("data:image")) {
    // Base64 data URL
    const base64Data = imageUrl.split(",")[1];
    imageBuffer = Buffer.from(base64Data, "base64");
  } else {
    // HTTP URL
    const response = await axios.get(imageUrl, { responseType: "arraybuffer" });
    imageBuffer = Buffer.from(response.data);
  }

  // Upload to Storage
  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);

  await file.save(imageBuffer, {
    metadata: {
      contentType: "image/jpeg",
    },
  });
}

async function createWatermarkedThumbnail(
  sourcePath: string,
  destPath: string,
  genId: string
): Promise<void> {
  const bucket = admin.storage().bucket();
  const sourceFile = bucket.file(sourcePath);

  // Download source image
  const [buffer] = await sourceFile.download();

  // Create watermarked thumbnail using sharp
  const watermarkedBuffer = await sharp(buffer)
    .resize(540, 960, { fit: "cover" })
    .composite([
      {
        input: Buffer.from(
          `<svg width="540" height="960">
            <text
              x="50%"
              y="50%"
              font-family="Arial"
              font-size="40"
              font-weight="bold"
              fill="white"
              fill-opacity="0.3"
              text-anchor="middle"
              transform="rotate(-45 270 480)"
            >WALLPAPERVERSE</text>
          </svg>`
        ),
        top: 0,
        left: 0,
      },
    ])
    .jpeg({ quality: 85 })
    .toBuffer();

  // Upload watermarked thumbnail
  const destFile = bucket.file(destPath);
  await destFile.save(watermarkedBuffer, {
    metadata: {
      contentType: "image/jpeg",
    },
  });
}
