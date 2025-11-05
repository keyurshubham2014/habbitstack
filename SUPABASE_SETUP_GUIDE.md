# Supabase Setup Guide for StackHabit

**Last Updated**: 2025-11-05
**Task**: 21 - Authentication & Cloud Sync

---

## Quick Start: Add Your Credentials

You mentioned you have the credentials stored in environment variables. Here's how to add them to the app:

### Step 1: Update the .env File

Open `/Users/keyur/Documents/Projects/Sample-flutter-app/.env` and replace the placeholder values:

```env
# Supabase Configuration
SUPABASE_URL=https://your-actual-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS...
```

**Where to get these**:
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Settings → API
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **Project API keys → anon public** → `SUPABASE_ANON_KEY`

### Step 2: Set Up Database Schema

Go to your Supabase dashboard → SQL Editor and run this SQL:

```sql
-- Create users table (linked to Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  premium_status BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ
);

-- Create habits table
CREATE TABLE IF NOT EXISTS habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT,
  color TEXT,
  is_anchor BOOLEAN DEFAULT FALSE,
  frequency TEXT NOT NULL DEFAULT 'daily',
  custom_days TEXT,
  grace_period_config TEXT,
  stack_id UUID,
  order_in_stack INTEGER,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create habit_stacks table
CREATE TABLE IF NOT EXISTS habit_stacks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  anchor_habit_id UUID,
  color TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create daily_logs table
CREATE TABLE IF NOT EXISTS daily_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL,
  notes TEXT,
  sentiment TEXT,
  tags TEXT[], -- PostgreSQL array for better querying
  voice_note_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create streaks table
CREATE TABLE IF NOT EXISTS streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_logged_date DATE,
  grace_period_active BOOLEAN DEFAULT FALSE,
  grace_strikes_used INTEGER DEFAULT 0,
  status TEXT DEFAULT 'perfect',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_stack_id ON habits(stack_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_user_id ON daily_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_habit_id ON daily_logs(habit_id);
CREATE INDEX IF NOT EXISTS idx_daily_logs_completed_at ON daily_logs(completed_at);
CREATE INDEX IF NOT EXISTS idx_streaks_user_id ON streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_streaks_habit_id ON streaks(habit_id);

-- Enable Row Level Security on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_stacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to make script re-runnable)
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Users can view own habits" ON habits;
DROP POLICY IF EXISTS "Users can insert own habits" ON habits;
DROP POLICY IF EXISTS "Users can update own habits" ON habits;
DROP POLICY IF EXISTS "Users can delete own habits" ON habits;
DROP POLICY IF EXISTS "Users can view own stacks" ON habit_stacks;
DROP POLICY IF EXISTS "Users can insert own stacks" ON habit_stacks;
DROP POLICY IF EXISTS "Users can update own stacks" ON habit_stacks;
DROP POLICY IF EXISTS "Users can delete own stacks" ON habit_stacks;
DROP POLICY IF EXISTS "Users can view own logs" ON daily_logs;
DROP POLICY IF EXISTS "Users can insert own logs" ON daily_logs;
DROP POLICY IF EXISTS "Users can update own logs" ON daily_logs;
DROP POLICY IF EXISTS "Users can delete own logs" ON daily_logs;
DROP POLICY IF EXISTS "Users can view own streaks" ON streaks;
DROP POLICY IF EXISTS "Users can insert own streaks" ON streaks;
DROP POLICY IF EXISTS "Users can update own streaks" ON streaks;
DROP POLICY IF EXISTS "Users can delete own streaks" ON streaks;

-- Row Level Security Policies

-- Users: Can view and update own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Habits: Full CRUD for own habits
CREATE POLICY "Users can view own habits"
  ON habits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own habits"
  ON habits FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own habits"
  ON habits FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own habits"
  ON habits FOR DELETE
  USING (auth.uid() = user_id);

-- Habit Stacks: Full CRUD for own stacks
CREATE POLICY "Users can view own stacks"
  ON habit_stacks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stacks"
  ON habit_stacks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stacks"
  ON habit_stacks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own stacks"
  ON habit_stacks FOR DELETE
  USING (auth.uid() = user_id);

-- Daily Logs: Full CRUD for own logs
CREATE POLICY "Users can view own logs"
  ON daily_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs"
  ON daily_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own logs"
  ON daily_logs FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own logs"
  ON daily_logs FOR DELETE
  USING (auth.uid() = user_id);

-- Streaks: Full CRUD for own streaks
CREATE POLICY "Users can view own streaks"
  ON streaks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streaks"
  ON streaks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own streaks"
  ON streaks FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own streaks"
  ON streaks FOR DELETE
  USING (auth.uid() = user_id);
```

### Step 3: Test the Connection

Run the app:
```bash
flutter run
```

You should see in the console:
```
✅ Supabase initialized successfully
📍 URL: https://your-project-id.supabase.co
```

If you see this, you're ready to go! If you see errors, check:
1. `.env` file exists in project root
2. Credentials are correct (no extra spaces)
3. Supabase project is active (not paused)

---

## Next Steps

Once credentials are added and database is set up:

1. ✅ Supabase initialized
2. ⏳ Build auth screens (Welcome, Signup, Login)
3. ⏳ Test email/password signup
4. ⏳ Implement data migration
5. ⏳ Test cloud sync

---

## Troubleshooting

### Error: "SUPABASE_URL not found in .env file"
- Make sure `.env` file exists in project root (next to `pubspec.yaml`)
- Check that the file is named exactly `.env` (not `.env.txt`)
- Ensure it's included in `pubspec.yaml` under `assets:`

### Error: "Invalid API key"
- Double-check the anon key from Supabase dashboard
- Make sure you copied the **anon** key, not the service role key
- No extra spaces or quotes around the key

### Error: "Network request failed"
- Check your internet connection
- Verify the Supabase project URL is correct
- Make sure the Supabase project is not paused (free tier pauses after inactivity)

### Database policies not working
- Ensure RLS is enabled on all tables
- Check that policies are created correctly
- Test with Supabase dashboard → Table Editor → Try inserting manually

---

## Security Notes

✅ **DO**:
- Keep `.env` file in `.gitignore` (already done)
- Use the anon key (it's safe for client-side)
- Enable Row Level Security (RLS) on all tables
- Test policies thoroughly

❌ **DON'T**:
- Never commit `.env` to version control
- Never use the service role key in the app
- Never disable RLS in production
- Never skip email verification for production

---

## Files Created

1. `lib/services/supabase_service.dart` - Supabase initialization
2. `lib/services/auth_service.dart` - Authentication logic
3. `lib/providers/auth_provider.dart` - Riverpod providers for auth state
4. `.env` - Environment variables (you need to fill this in)
5. `.env.example` - Template for credentials

---

**Status**: Infrastructure Ready
**Next**: Add your credentials to `.env` and run the SQL schema in Supabase
