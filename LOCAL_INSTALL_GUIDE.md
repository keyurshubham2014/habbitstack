# Quick Setup: Add Your Supabase Credentials

Since you have the Supabase credentials in environment variables, here's the quickest way to get started:

## Step 1: Update .env File (1 minute)

Open `.env` in the project root and add your credentials:

```bash
# Replace these with your actual values from environment variables
SUPABASE_URL=<YOUR_SUPABASE_URL>
SUPABASE_ANON_KEY=<YOUR_SUPABASE_ANON_KEY>
```

If you have them as shell environment variables, you can run:
```bash
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env
```

## Step 2: Run the Database Schema (5 minutes)

Go to Supabase Dashboard → SQL Editor and copy-paste the SQL from:
`SUPABASE_SETUP_GUIDE.md` (lines 23-191)

Or use this shortcut - I've prepared the full SQL schema there.

## Step 3: Test It

```bash
flutter pub get
flutter run
```

You should see:
```
✅ Supabase initialized successfully
📍 URL: https://your-project-id.supabase.co
```

---

## What's Been Built So Far

✅ Dependencies added (supabase_flutter, flutter_secure_storage, etc.)
✅ SupabaseService - Reads credentials from .env
✅ AuthService - Email/password, Google, Apple login
✅ Auth Providers - Riverpod state management for auth

⏳ **Next (I'll build these now)**:
- Welcome Screen
- Signup Screen
- Login Screen
- Forgot Password Screen
- Update main.dart routing

---

**Want me to continue?** Let me know when you've:
1. Added credentials to `.env`
2. Run the SQL schema in Supabase

Then I'll finish the auth screens and you can test the full flow!
