# Scripts

## Seed Data Script

This script populates the Firestore database with sample wallpapers for testing.

### Setup

1. Download your Firebase service account key:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `serviceAccountKey.json` in this directory

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run the seed script:
   ```bash
   npm run seed
   ```

### What it does

- Creates 50 sample wallpapers across various categories
- Creates a test user with 100 credits
- Sets up proper Firestore structure

### Note

The wallpapers created by this script have placeholder storage paths. In production, you would need to upload actual images to Cloud Storage and update the paths accordingly.
