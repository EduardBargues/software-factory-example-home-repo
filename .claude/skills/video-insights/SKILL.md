---
name: video-insights
description: Turn a video into a standalone, consultable help-skill. Given a public video URL (downloaded with yt-dlp) or a transcript the user supplies, extract the speaker's vocabulary, key concepts, decisions (their chain of thought), and recommendations, and write them into a new course-style skill at .claude/skills/<slug>/ that an agent can later load to answer questions and foresee solutions to the user's real-world problems. Use when the user wants to "make a skill from this video", "distill a talk/tutorial", or capture what someone in a video teaches.
---

You turn **one video** into a new **standalone help-skill** — a problem-driven routing map an agent consults when the user is stuck, built from what the person in the video says and decides. The generated skill lives at `.claude/skills/<slug>/SKILL.md` and sits alongside the user's other skills, so any agent can load it by its frontmatter `description` and help the user with problems the video speaks to.

This skill is a **generator**. It mirrors the house style of the `course-*` skills (which `update-workshop-skill` produces): concise entries, a load-bearing **Source** link, and a **"When it helps"** trigger on every situational entry so problem-driven matching works.

## Input

The user gives you **one** of:
- A **public video URL** (YouTube or anything `yt-dlp` supports). You download its captions yourself.
- A **transcript (or notes) they supply directly** — used for private videos they can't share by URL. Skip the download and go straight to extraction.

They may also give a **destination skill name**; if they don't, derive one (see "Create the skill").

## Step 1 — Obtain the transcript

Skip this entire step if the user supplied a transcript directly (record its provenance as **user-supplied**).

Always use the **`yt-dlp`** CLI to fetch captions. Never transcribe audio — there is no Whisper/audio fallback. Work the source ladder in order:

1. **Human/official captions** — the author's own subtitles. Preferred: most accurate.
2. **Auto-generated captions** — YouTube's machine captions. Carry a mistranscription caveat (names, tools, and jargon are often wrong).
3. **No captions at all** → **stop and ask the user to supply a transcript.** Do not try to transcribe the audio.

Default to **English** (`en`). Check what exists first, then download:

```bash
# See which tracks exist and whether a manual (human) English track is present.
yt-dlp --list-subs "<URL>"

# Download captions only (no video). --write-sub = manual, --write-auto-sub = auto.
yt-dlp --skip-download --write-sub --write-auto-sub --sub-lang "en.*" \
  --sub-format "vtt" --restrict-filenames -o "%(title)s.%(ext)s" "<URL>"
```

Record which source you actually used (manual vs auto-generated) — it becomes the **provenance** line in the skill.

### Clean the captions into a flowing transcript

Auto-caption VTT is full of rolling duplicate lines and inline timestamp tags. Convert it to a **single flowing, de-duplicated paragraph** (the same style as the `.txt` transcripts already in the user's workshop folders), using a script like:

```bash
python3 - "<the .vtt file>" <<'PY'
import re, sys
raw = open(sys.argv[1], encoding="utf-8").read()
out = []
for ln in raw.splitlines():
    if ln.startswith(("WEBVTT", "Kind:", "Language:")) or "-->" in ln:
        continue
    ln = re.sub(r"<[^>]+>", "", ln).strip()   # strip <timestamp> and <c> tags
    if ln and (not out or out[-1] != ln):      # drop consecutive rolling repeats
        out.append(ln)
text = re.sub(r"\s+", " ", " ".join(out)).strip()
open("transcript.txt", "w", encoding="utf-8").write(text + "\n")
PY
```

Sanity-check the result (a quick scan for back-to-back repeated phrases) and **delete the intermediate `.vtt` files** — keep only the clean transcript.

## Create the skill

- **Slug & home.** Derive a short, topic-based kebab slug from the video title (e.g. `shipping-features-with-skills`), unless the user gave a name — then use theirs. Create `.claude/skills/<slug>/SKILL.md`.
- **Co-locate the transcript.** Save the cleaned transcript as `<slug>.transcript.txt` **inside the same folder** as the generated skill — it is the source of truth. Do not duplicate it into the user's `videos/` directory.
- **One skill per video, standalone.** Never append to or enrich another skill. If a skill with that slug already exists, confirm with the user before overwriting.
- **Source links** in every entry point at the co-located transcript: `` [`transcript`](./<slug>.transcript.txt) ``.

## What to extract

Watch the whole transcript. For each candidate item, apply the **inclusion bar**, then categorise it.

### Inclusion bar — four tests

Extract an item only if it passes **all four**:

1. **Transferable** — it applies beyond the video's specific example or product. (A detail true only of the demo app fails.)
2. **Durable** — not tied to a tool version or a passing aside that will age out.
3. **Non-obvious** — a competent mid-level engineer wouldn't already treat it as default. Skip truisms.
4. **Load-bearing** — a point the speaker actually makes, not an incidental remark.

**Standing exception — always capture named skills/tools and decisions.** Any named, invocable skill the speaker teaches or uses (e.g. `/grill-with-docs`, `/retro`), and any real decision they make (below), are always in scope even if they'd otherwise read as too specific.

### Categories

- **Summary** — a short orientation (3–6 sentences): who the speaker is, what the video covers, and the biggest takeaways. Not a transcript recap.
- **Vocabulary** — a named thing (technique, artifact, labelled concept, or a `/`-skill). Definitional; no trigger.
- **Key Concept** — a claim about how things work (a mental model, a cause/effect, a "why"). Gets a "When it helps" trigger.
- **Decision Log** — the speaker's **chain of thought** at a real fork in the video. This is the highest-value capture for the user. One entry per decision, preserving **Situation → Options considered → Choice → Why**. Gets a "When it helps" trigger. Keep the alternatives and the reasoning — they are the insight; do not flatten a decision into a bare Do/Don't.
- **Do / Don't** — an instruction to adopt or avoid a practice. Each gets a "When it helps" trigger.

### The "When it helps" trigger

For every **Key Concept**, **Decision Log** entry, and **Do/Don't**, write the concrete situation or symptom — in the user's words — that should make an agent reach for this entry ("Your team keeps…", "An agent is…"). Vocabulary is definitional and gets no trigger.

Examples are allowed only as inline illustrations of a general principle, never as the subject of an entry.

## Format of the generated skill

Mirror the `course-*` skills. Frontmatter first (the `description` carries all the routing weight — pack it with "load when the user's problem involves…" symptom triggers and any skill names). Then the body, groups in this order, including only those that have entries:

```
---
name: <slug>
description: Distilled knowledge from the video "<Title>"<, by <Speaker> if known>. Load when the user's problem involves <compact symptom list and skill/tool names>. Built from the video transcript; may be loaded alongside other skills when a problem spans sources.
---

# <Title> — Video Notes

Distilled knowledge from the video **"<Title>"**<, by **<Speaker>**>. Use this when the user is stuck on a problem about <areas>: scan the **When it helps** entries to find a match, then follow the **Source** link to the transcript for full context.

**When the question is more detailed than the entries here, or this skill has no entry that covers it, read the full transcript (`./<slug>.transcript.txt`) before answering.** These notes are a routing map, not the whole video — the transcript is the source of truth. Search it for the relevant part rather than guessing or filling the gap from general knowledge, and if the transcript doesn't address it either, say so plainly.

_Transcript provenance: <official captions | auto-generated captions (expect mistranscribed names/terms) | user-supplied>._ _Source:_ [`transcript`](./<slug>.transcript.txt)

## Summary

<3–6 sentences.>

**Vocabulary**

| Term | Source | Description |
| --- | --- | --- |
| **Title** | [`transcript`](./<slug>.transcript.txt) | Definition. |

**Key Concepts**

| Concept | When it helps | Source | Description |
| --- | --- | --- | --- |
| **Title** | The situation/symptom, in the user's words | [`transcript`](./<slug>.transcript.txt) | One to three sentences. |

**Decision Log**

<One block per decision — not a table:>

**Decision — <short label>**

_When it helps:_ <the user's situation this maps to>. _Source:_ [`transcript`](./<slug>.transcript.txt)
- **Situation:** <what the speaker faced>
- **Options considered:** <the alternatives they weighed>
- **Choice:** <what they picked>
- **Why:** <their reasoning>

**Do**

| Recommendation | When it helps | Source | Description |
| --- | --- | --- | --- |
| **Title** | The situation/symptom | [`transcript`](./<slug>.transcript.txt) | The instruction. |

**Don't**

| Recommendation | When it helps | Source | Description |
| --- | --- | --- | --- |
| **Never …** | The situation/symptom | [`transcript`](./<slug>.transcript.txt) | The instruction. |
```

Cell rules: bold name cells; keep every cell free of unescaped `|`; keep descriptions concise since the transcript holds the depth; join multiple situations in a "When it helps" cell with ` · `.

## Rules

- Attribute everything to the person in the video; this skill captures *their* knowledge and reasoning, not general best practice.
- Don't capture things the speaker explicitly parks or says you won't need.
- Keep entries self-contained: a reader who hasn't watched the video should understand them.
- Always include the **"read the full transcript when the question is more detailed than these notes, or uncovered"** instruction near the top of the generated skill (it's in the template). The generated skill is a routing map; the co-located transcript is its source of truth, and an agent must fall back to it instead of guessing.
- If captions were auto-generated, be alert to garbled names/tools when writing entries, and keep the provenance caveat visible.
- After writing, give a short run summary: the slug and path of the skill you created, the transcript source/provenance, and how many entries landed in each section (Vocabulary / Key Concepts / Decision Log / Do / Don't).
