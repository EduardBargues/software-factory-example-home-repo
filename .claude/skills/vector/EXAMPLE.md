# A finished workflow map: the cohort Discord

Answering the cohort's questions in Discord, after all six VECTOR steps.

**Definition of done:** every thread has a reply, or is marked as a duplicate. _Automated check: no unanswered threads._

**Before the first run:**

- How I talk: a style guide
- The course: already in course search

**The agent's turn**, across every thread at once:

1. **Task:** Find all the unanswered threads
   - Uses: Discord
2. **Task:** Read each thread
   - Uses: Discord
3. **Task:** Search for earlier threads asking the same thing
   - Uses: Discord
4. **Task:** Search for the lesson or resource
   - Uses: course search, Google
5. **Decide:** Decide whether it needs a reply, or is a duplicate
   - **The agent's:** it only needs the thread and the earlier threads
6. **Decide:** Decide what to say
   - Uses: my style guide
   - **The agent's:** it only needs my style guide
7. **Task:** Draft the replies
   - Uses: a drafts doc

_Handoff artifact: for each thread, a draft reply or a duplicate link._

**Your turn:**

8. **Decide:** Check each draft reply and duplicate link

**The agent's turn:**

9. **Task:** Post the replies
   - Uses: Discord
   - **One-way door:** the post is public
10. **Remember:** What I learned
    - Saved to: the course wiki

## How it got here

- **Existing process:** seven steps per thread, from "Read the thread" to "Post the reply". "Decide what to say" used `memory (how I talk)`, so it was the user's.
- **Trust:** "Post the reply" became a one-way door, split off from "Draft the reply". "Decide whether it needs a reply" was the agent's from the start.
- **Order:** with "Decide what to say" still the user's, the map had five turns.
- **Remember:** writing a style guide moved "Decide what to say" to the agent, so the five turns shrank to three.
