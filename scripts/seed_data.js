/**
 * Seed Data Script for WallpaperVerse
 *
 * This script creates sample wallpapers in Firestore for testing.
 * Run with: node scripts/seed_data.js
 *
 * Prerequisites:
 * - Firebase Admin SDK configured
 * - Service account key JSON file
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const categories = ['Nature', 'Abstract', 'Minimal', 'Dark', 'Colorful', 'Space', 'Urban', 'Animals'];
const styles = ['realistic', 'artistic', 'anime', 'digital-art', 'minimalist', 'abstract'];
const colors = ['blue', 'red', 'green', 'purple', 'orange', 'pink', 'black', 'white', 'yellow'];

const sampleWallpapers = [
  {
    title: 'Mountain Sunset',
    tags: ['mountain', 'sunset', 'nature', 'landscape'],
    colors: ['orange', 'purple', 'blue'],
    category: 'Nature',
    style: 'realistic',
    description: 'Beautiful sunset over mountain peaks',
  },
  {
    title: 'Abstract Waves',
    tags: ['abstract', 'waves', 'colorful', 'modern'],
    colors: ['blue', 'purple', 'pink'],
    category: 'Abstract',
    style: 'abstract',
    description: 'Flowing abstract wave patterns',
  },
  {
    title: 'Minimal Dark',
    tags: ['minimal', 'dark', 'simple', 'elegant'],
    colors: ['black', 'white'],
    category: 'Minimal',
    style: 'minimalist',
    description: 'Clean and minimal dark design',
  },
  {
    title: 'Cosmic Galaxy',
    tags: ['space', 'galaxy', 'stars', 'cosmic'],
    colors: ['purple', 'blue', 'black'],
    category: 'Space',
    style: 'realistic',
    description: 'Stunning view of distant galaxies',
  },
  {
    title: 'Urban Night',
    tags: ['city', 'urban', 'night', 'lights'],
    colors: ['blue', 'orange', 'black'],
    category: 'Urban',
    style: 'realistic',
    description: 'City lights at night',
  },
  {
    title: 'Geometric Patterns',
    tags: ['geometric', 'pattern', 'colorful', 'modern'],
    colors: ['red', 'yellow', 'blue'],
    category: 'Abstract',
    style: 'digital-art',
    description: 'Bold geometric patterns',
  },
  {
    title: 'Ocean Waves',
    tags: ['ocean', 'waves', 'water', 'blue'],
    colors: ['blue', 'white'],
    category: 'Nature',
    style: 'realistic',
    description: 'Crystal clear ocean waves',
  },
  {
    title: 'Forest Path',
    tags: ['forest', 'nature', 'trees', 'green'],
    colors: ['green', 'brown'],
    category: 'Nature',
    style: 'realistic',
    description: 'Peaceful forest pathway',
  },
  {
    title: 'Neon Dreams',
    tags: ['neon', 'cyberpunk', 'futuristic', 'colorful'],
    colors: ['pink', 'purple', 'blue'],
    category: 'Abstract',
    style: 'digital-art',
    description: 'Vibrant neon lights',
  },
  {
    title: 'Starry Night',
    tags: ['stars', 'night', 'sky', 'space'],
    colors: ['black', 'blue', 'white'],
    category: 'Space',
    style: 'realistic',
    description: 'Beautiful starry night sky',
  },
];

async function seedWallpapers() {
  console.log('Starting to seed wallpapers...');

  const batch = db.batch();
  let count = 0;

  for (let i = 0; i < 50; i++) {
    const template = sampleWallpapers[i % sampleWallpapers.length];
    const docRef = db.collection('wallpapers').doc();

    const wallpaper = {
      title: `${template.title} ${i + 1}`,
      tags: template.tags,
      colors: template.colors,
      category: template.category,
      style: template.style,
      description: template.description,
      resolution: {
        width: 1080,
        height: 1920,
      },
      // Placeholder paths - in production, these would be actual storage URLs
      storagePath: `public/wallpapers/${docRef.id}/full.jpg`,
      thumbnailPath: `public/wallpapers/${docRef.id}/thumb.jpg`,
      price: Math.floor(Math.random() * 3) + 1, // 1-3 credits
      featured: i < 10, // First 10 are featured
      sales: Math.floor(Math.random() * 100),
      createdAt: admin.firestore.Timestamp.now(),
    };

    batch.set(docRef, wallpaper);
    count++;

    console.log(`Added: ${wallpaper.title}`);
  }

  await batch.commit();
  console.log(`\nSuccessfully seeded ${count} wallpapers!`);
}

async function createSampleUser() {
  console.log('\nCreating sample user...');

  const userId = 'sample_user_123';
  const userRef = db.collection('users').doc(userId);

  await userRef.set({
    email: 'test@wallpaperverse.com',
    displayName: 'Test User',
    photoURL: null,
    credits: 100,
    createdAt: admin.firestore.Timestamp.now(),
    lastActiveAt: admin.firestore.Timestamp.now(),
  });

  console.log('Sample user created with 100 credits!');
}

async function main() {
  try {
    await seedWallpapers();
    await createSampleUser();
    console.log('\n✅ Seed data script completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding data:', error);
    process.exit(1);
  }
}

main();
