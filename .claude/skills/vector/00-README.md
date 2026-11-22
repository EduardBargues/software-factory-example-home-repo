# VECTOR: mapping a workflow onto an agent

VECTOR is a method for working out how to hand a piece of knowledge work to an AI agent. Take a workflow you already do (half an hour to two hours of work in one go, like clearing your inbox every morning) and go through six questions in order:

| Step | Question |
|---|---|
| **V**erification | How do we verify the work was done? |
| **E**xisting process | What's the existing process? |
| **C**ontext | What context does it need? |
| **T**rust | What can you trust it to do? |
| **O**rder | What's the new order of turns? |
| **R**emember | What should it remember? |

The result is a **workflow map**: what "done" looks like and how it's checked, every step and what it uses, which steps can't be undone, which decisions the agent can make, how the work splits into turns between you and the agent, and what the agent needs to remember between runs.

## Files

- **`SKILL.md`**: the `/vector` skill. It interviews you through the six steps, one question at a time, in the environment where the workflow will run.
- **`EXAMPLE.md`**: a finished workflow map, for answering questions in a cohort Discord.

`SKILL.md` relies on a `grilling` skill to run the interview.
