---
name: vector
description: "VECTOR, a step-by-step grilling that maps a piece of knowledge work onto an agent. Use when someone wants to work out how to use AI for a workflow they already do, or to turn one into a document or scripts an agent runs."
---

# Workflow mapping: VECTOR

A **workflow** is a chunk of work that takes half an hour to two hours in one go, like clearing your inbox every morning. A five-minute action isn't worth mapping.

Some work happens in small bits all day, like capturing content during a build. Split it in two: an **automation** that collects the bits (such as recording), and a workflow that processes the whole batch in one sitting (such as harvesting the recordings). Map the batch workflow, and note the automation in one line.

A **workflow map** is the shared understanding, between you and the user, of one workflow and how an agent will run it. The six VECTOR steps below build it in order, each from the one before.

**This environment is where the workflow will run.** The tools, connectors, files and permissions you have here are the ones the agent will have on every run, so map against them.

## How to run it

Invoke the `grilling` skill and grill the user through the steps, **one step at a time** and **one question per round**:

1. The current step's design tree is the only thing you grill on.
2. Grill until the step's **Output** is settled. Write that output down in the conversation and ask the user to confirm it.
3. Once they confirm, move to the next step.

Ask each question in one or two short sentences: give a little context first, then the question. Write in ASD-STE100 Simplified Technical English, and use the words this skill defines (workflow, Task, Decide, turn, one-way door).

The map is done when all six outputs are confirmed. Then show it whole, laid out like [EXAMPLE.md](./EXAMPLE.md).

## 1. Verification: How do we verify the work was done?

The workflow's **definition of done** is what it looks like when it's done, and how you'd know. Check each part the cheapest reliable way:

1. **Automated check**: code that gives the same answer every time, like "no unanswered threads".
2. **Automated review**: another agent judging the work.
3. **Human review**: the user reading what was produced. The last resort, though sometimes you can't avoid it.

**Design tree:**

- Which workflow? Check it's half an hour to two hours of work in one go. If it happens in small bits all day, find the batch: what would you do with everything collected, in one sitting?
- What does it look like when it's done? Push for something observable, like "every thread has a reply", rather than "the inbox is handled".
- For each part of done: how would you know? Recommend the highest rung of the ladder above that can check it.

**Output:** a definition of done, with how each part is checked.

## 2. Existing process: What's the existing process?

The existing process is how the user does the workflow today, with or without AI. Walk through one real run, such as the last time they did it, in order. Each step is exactly one of:

- **Task:** doing something, such as reading a thread or posting a reply
- **Decide:** making a judgement call

Group steps that repeat per item under a line like "For each thread:". If someone other than the user does a step, such as a reviewer or the team, say who, by name or role. If an agent already does a step, say so.

**Design tree:**

- Which real run will you walk through?
- What did you do first? Then, after each answer: what did you do next? Carry on until the definition of done is met.
- Who did this step: you, an agent, or someone else?
- When a step mixes doing and judging ("I read it and replied"), split it into a Task and a Decide.
- Which steps did you repeat for each item?

**Output:** a numbered list of Tasks and Decides, in the order the user did them.

## 3. Context: What context does it need?

Each step's **context** is what it uses, written as **Uses:**. The user's memory counts: anything they knew before starting, like how they talk. Write it as `memory (how I talk)`.

Before grilling, explore this environment yourself: the tools, CLIs, connectors, files and documents you can reach. What you can reach here is what the agent can reach on every run.

**Design tree**, for each step in order:

- What do you look at or open to do this step: which app, document or site? Check whether you can reach it here, and recommend the tool or file that does it.
- What do you already know that you bring to it? Decides usually lean on memory: how they talk, where the project is going, what the customer wants.
- For anything you can't reach here: how will it get into this environment, such as a connector, a CLI or an export? Or does the step stay the user's?

**Output:** every step has its Uses, each marked as reachable here, memory, or missing (with how it will be added).

## 4. Trust: What can you trust it to do?

Make two marks:

- **One-way door:** a task that can't be walked back, such as sending, posting in public, deleting or paying. Split it into a task you can walk back and a smaller one-way door: draft the email, then send it.
- **The agent's:** a decision the agent can make, because everything it uses is something the agent can read, like a tool or a document. If any of it is only in the user's memory, the decision stays the user's. Say what the decision needs. If the agent gets one wrong, the user undoes it in their turn.

Everything the agent reads is sent to the model provider running it, and some tools send data to other services too, such as image or video generation, search, or transcription. So trust also means the user has the right to send each piece of that data to each service it reaches: customer records, other people's messages, anything under a contract or NDA, personal data.

**Design tree:**

- Propose the one-way doors yourself, from the Tasks and what their tools do here, with how to split each. Ask: are these all of them?
- For each Decide: is everything it uses something the agent can read? If so, recommend marking it the agent's and say what it needs. If any of it is memory, it stays the user's for now; Remember can change that.
- List every service the data goes to: the model, plus any tool that sends data out. Ask: are these all of them?
- For each data source in Uses, and each service it reaches: do you have the right to send it there? Anything they don't have the right to send comes out of the workflow, goes to a service they do have the right to use, or the step stays the user's.

**Output:** every one-way door marked, every decision marked as the agent's or left as the user's, and every data source confirmed as one the user has the right to send to each service it reaches.

## 5. Order: What's the new order of turns?

The new order is the same steps, bundled into **turns**. Steps that repeat per item run across every item at once.

- **The agent's turn** runs as far as it can, until it reaches a one-way door or a decision it can't make. It ends with a **handoff artifact**: a report of what it did, with its drafts.
- **The user's turn:** undo anything they disagree with, check the drafts, and make their decisions. Then the agent carries on.

- **Someone else's turn:** a step done by someone other than the user, such as a review. Name the turn after the person or role, like "the editor's turn". The agent's turn before it ends with a handoff artifact for them, and the agent waits.

If the agent can make every decision, that's three turns: the agent's, the user's, then the agent's one-way doors. Each decision it can't make, and each step someone else does, adds turns.

**Design tree:**

- Propose the turns from the Trust marks, then ask: does this order work?
- For each handoff artifact: what does the user need to see in it to take their turn quickly?
- In each of the user's turns, and each turn someone else takes: what will they check, and what will they decide?

**Output:** the steps regrouped into turns, each agent turn ending in a handoff artifact.

## 6. Remember: What should it remember?

The agent can't read the user's memory, so give it a **memory system**: save what's in their memory somewhere in this environment the agent can read, such as a wiki or a document. There are two kinds:

- **What the workflow uses from memory**, found in Context. Write it down once, before the first run.
- **What each run teaches.** Add a **Remember:** step right after the step it's learned in, with **Saved to:** naming where it goes.

If you could look it up again, it isn't a memory.

**Design tree:**

- For each `memory (…)` in Context: where in this environment will it be written down before the first run?
- What does a run teach you that you'd want next time? After which step do you learn it, and where should it be saved?
- Once a decision's memory is written down, the agent can make it. Recommend marking it the agent's in Trust and redoing the turns. Ask: do the turns shrink as expected?

**Output:** a "Before the first run" list, the Remember steps, and the turns redone with the newly trusted decisions.

## After the map

The map is the deliverable. From it, the user can optionally have you turn it into:

- **A document:** the map written up for the agent to follow each run, such as a skill.
- **Scripts:** the agent's turns as code, with the Verification step's automated checks alongside.
