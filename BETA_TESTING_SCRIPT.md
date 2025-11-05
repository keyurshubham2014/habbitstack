# StackHabit Beta Testing Script

Thank you for helping test StackHabit! Your feedback will help make this app better for everyone.

**Estimated Time**: 30-40 minutes (spread over 2-3 days)
**Version**: 1.0.0-mvp

---

## What is StackHabit?

StackHabit is a habit tracking app that uses **reverse logging** (log what you've done, not what you plan to do) and **habit stacking** (link new habits to existing ones) to help you build sustainable habits without the pressure of traditional trackers.

### Key Features You'll Test:
1. **Reverse Logging**: Log activities after completing them
2. **Habit Stacking**: Build routines by linking habits together
3. **Forgiving Streaks**: Grace periods when you miss days
4. **Bounce Back**: 24-hour window to save broken streaks
5. **Notes & Tags**: Add reflections with searchable hashtags

---

## Setup (5 minutes)

### Step 1: Install the App
- **iOS**: Install from TestFlight link: [YOUR_TESTFLIGHT_LINK]
- **Android**: Download APK from: [YOUR_APK_LINK]

### Step 2: First Launch
1. Launch the app
2. Grant permissions when requested (notifications, microphone - optional)
3. Explore the main screen

### Questions:
- Did the app launch without errors?
- Do you understand what the app does from the home screen?
- Are all 5 tabs visible at the bottom?

---

## Task 1: Log Your First Activity (5 minutes)

Let's test the core feature: reverse logging.

### Steps:
1. Tap the **"Log Activity"** button (floating action button)
2. Tap **"Create new habit"** at the bottom
3. Enter habit name: **"Morning Coffee"**
4. Choose an icon (coffee cup or similar)
5. Set the time to **now** (or earlier today)
6. Choose a sentiment: **Happy** (green face)
7. In the Notes field, type: **"First test log #morning #test"**
8. Notice the character counter at the bottom (should show something like "32/500")
9. Tap **Save**

### Questions:
- ✅ / ❌ Was this process intuitive?
- ✅ / ❌ Did the log appear in your Today's Log screen?
- ✅ / ❌ Did you notice the hashtags in your note?
- ✅ / ❌ Any confusing steps?
- **Bugs/Issues**: ___________________________________________

---

## Task 2: Test Voice Input (3 minutes - Optional)

If you granted microphone permission, let's test voice notes.

### Steps:
1. Tap **"Log Activity"** again
2. Select **"Morning Coffee"** from the dropdown (existing habit)
3. Tap the **microphone icon** in the Notes field
4. Speak a short note: "This is a test of voice input"
5. Tap **Done** when it transcribes
6. Verify the text appeared in Notes
7. Tap **Save**

### Questions:
- ✅ / ❌ Did voice recognition work?
- ✅ / ❌ Was the transcription accurate?
- ✅ / ❌ Easy to use?
- **Bugs/Issues**: ___________________________________________

---

## Task 3: Search Your Notes (3 minutes)

Let's test the search feature with tags.

### Steps:
1. From Today's Log screen, tap the **search icon** (magnifying glass) in the top-right
2. Notice the "Recent Tags" section - you should see **#morning** and **#test**
3. Tap the **#morning** tag chip
4. Your log should appear in search results
5. Now search for **"coffee"** (type it in the search bar)
6. Your log should appear again
7. Tap a result to view/edit it
8. Close the search

### Questions:
- ✅ / ❌ Did search find your notes?
- ✅ / ❌ Did tag filtering work?
- ✅ / ❌ Was it easy to understand?
- **Bugs/Issues**: ___________________________________________

---

## Task 4: Create a Habit Stack (10 minutes)

Now let's test the habit stacking feature.

### Steps:
1. Go to the **"Build Stack"** tab (second tab)
2. Tap **"Create Stack"** (or FAB)
3. Enter stack name: **"Morning Routine"**
4. Enter description: **"My morning habits"**
5. Select **"Morning Coffee"** as your **Anchor Habit** (this should be suggested if you logged it earlier)
6. Tap **"Add Habit"** to add more habits to the stack:
   - Add **"Brush Teeth"**
   - Add **"10 Pushups"**
   - Add **"Check Email"**
7. Try **drag-and-drop** to reorder habits (long-press a habit, then drag up/down)
8. Tap **Save Stack**

### Questions:
- ✅ / ❌ Do you understand what an "anchor habit" is?
- ✅ / ❌ Did the stack save successfully?
- ✅ / ❌ Did drag-and-drop work smoothly?
- ✅ / ❌ Was the visual flow clear (Anchor → Habit 1 → Habit 2)?
- **What would make this feature clearer?**: ___________________________________________
- **Bugs/Issues**: ___________________________________________

---

## Task 5: Build a Small Streak (2-3 days)

This task requires logging habits over multiple days.

### Day 1:
1. Log "Morning Coffee" today with a note
2. Go to **"Streaks"** tab (third tab)
3. You should see "Morning Coffee" with a **1-day streak**

### Day 2:
1. Log "Morning Coffee" again tomorrow
2. Check Streaks tab - should show **2-day streak**
3. Notice the **calendar heatmap** at the bottom showing green days

### Day 3 (Optional - Test Grace Period):
1. **Don't log** "Morning Coffee" today
2. Check Streaks tab tomorrow
3. You should see a **yellow** grace period warning

### Questions:
- ✅ / ❌ Did the streak count correctly?
- ✅ / ❌ Are the colors clear (green = perfect, yellow = grace period)?
- ✅ / ❌ Is the calendar heatmap easy to read?
- ✅ / ❌ Did you understand grace periods?
- **Bugs/Issues**: ___________________________________________

---

## Task 6: Test Bounce Back (Optional)

If you missed a day and see a "Bounce Back" card on Today's Log screen, try using it.

### Steps:
1. Look for a **gold/yellow** "Save Your Streak" card at the top of Today's Log
2. Tap **"Bounce Back"**
3. This creates a backdated log to save your streak
4. Check Streaks tab - your streak should be saved (green, not red)

### Questions:
- ✅ / ❌ Was the bounce back concept clear?
- ✅ / ❌ Did it work as expected?
- ✅ / ❌ Did your streak get saved?
- **Bugs/Issues**: ___________________________________________

---

## Task 7: Test Notifications (2 minutes)

Let's set up a daily reminder.

### Steps:
1. Go to **"Settings"** tab (fifth tab)
2. Find **"Daily Reminder"** toggle
3. Enable it
4. Set a time (maybe 1 minute from now for testing)
5. Wait for the notification to arrive
6. Tap the notification - it should open the app

### Questions:
- ✅ / ❌ Did the notification fire at the scheduled time?
- ✅ / ❌ Did tapping the notification open the app?
- ✅ / ❌ Was the notification message clear?
- **Bugs/Issues**: ___________________________________________

---

## Task 8: Test Tag Suggestions (3 minutes)

Let's test the tag suggestion feature.

### Steps:
1. Tap **"Log Activity"**
2. Select any habit
3. In the Notes field, start typing a note
4. If you have recent tags, you should see **"Recent tags:"** chips below the notes field
5. Tap a tag chip (like #morning) - it should insert into your notes
6. Add a new tag manually: **#evening**
7. Save the log
8. Create another log and check if #evening appears in suggestions

### Questions:
- ✅ / ❌ Did tag suggestions appear?
- ✅ / ❌ Did tapping a chip insert the tag?
- ✅ / ❌ Was this feature helpful?
- **Bugs/Issues**: ___________________________________________

---

## Task 9: Explore & Break Things! (10 minutes)

Now spend some time trying to find bugs or confusing UX:

### Things to Try:
- Create multiple logs on the same day
- Edit a log you created yesterday
- Delete a log (confirm it's really gone)
- Try creating a very long note (500 characters)
- Create a stack with 10+ habits
- Log a habit at midnight (11:59 PM or 12:00 AM)
- Force-quit the app and reopen (check if data persists)
- Try switching tabs rapidly
- Scroll through long lists
- Try unusual habit names (emoji, symbols, very long names)

### Questions:
- **What broke or behaved strangely?**: ___________________________________________
- **What was confusing?**: ___________________________________________
- **What frustrated you?**: ___________________________________________

---

## Final Feedback

### Overall Experience

1. **What did you like most about the app?**
   _________________________________________________________________

2. **What frustrated you the most?**
   _________________________________________________________________

3. **What's confusing or unclear?**
   _________________________________________________________________

4. **Would you use this app daily?** (Circle one)
   - YES - I'd use it every day
   - MAYBE - If certain things improved (what?): _______________
   - NO - It's not for me because: ___________________________

5. **How would you rate the app overall?** (1-5 stars)
   ⭐ ⭐ ⭐ ⭐ ⭐

6. **Which feature do you think needs the most improvement?**
   - [ ] Today's Log (logging activities)
   - [ ] Build Stack (habit stacking)
   - [ ] Streaks (tracking consistency)
   - [ ] Notifications
   - [ ] Search & Tags
   - [ ] Other: ___________________________________________

### Device Information

- **Device Model**: (e.g., iPhone 14, Google Pixel 6)
- **OS Version**: (e.g., iOS 17.2, Android 13)
- **Any crashes?**: YES / NO
  - If yes, when?: ___________________________________________

---

## Bugs You Found

Please list any bugs or issues you encountered:

| # | Where | What Happened | How Often |
|---|-------|---------------|-----------|
| 1 |       |               | Always / Sometimes / Once |
| 2 |       |               | Always / Sometimes / Once |
| 3 |       |               | Always / Sometimes / Once |

---

## Submitting Your Feedback

**Option 1 - Email**:
Send your responses to: **[YOUR_EMAIL]**

**Option 2 - Google Form**:
Fill out this form: **[YOUR_FORM_LINK]**

**Option 3 - Direct Message**:
Message me on [platform] with your feedback

---

## Thank You! 🙏

Your feedback is incredibly valuable. As a thank-you:
- You'll get early access to all future features
- Your name in the app credits (if you want)
- A lifetime premium subscription when it launches (free!)

**Questions?** Contact me at [YOUR_EMAIL] or [YOUR_PHONE]

---

**Testing Script Version**: 1.0
**Last Updated**: 2025-11-05
