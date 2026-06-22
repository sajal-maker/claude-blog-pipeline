---
description: Generate an on-brand hero banner image for a blog using an image-generation MCP, and wire it into the draft.
---

# /blog-banner — Blog Hero Banner Generator

**Usage:** `/blog-banner <brand-slug> "<topic or title>"`
`$ARGUMENTS` — brand slug + topic/title.

## Step 1 — Load context
Read `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md` for **colors** (accent/lightTint/darkPanel), voice, and aesthetic. If a matching draft `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__*.md` exists, read its `title`, `primary_keyword`, and `hero_alt`.

## Step 2 — Build the prompt
Compose one vivid image prompt baking in:
- Subject = the blog topic in the brand's product context.
- **Brand palette** = reference the actual hex values so the banner matches the page.
- Composition = wide hero, **21:9** feel, clear negative space on one side for an overlaid headline, editorial/premium lighting, **no embedded text** in the image.
- Mood from the brand voice.

## Step 3 — Generate
1. Use an available image-generation MCP tool (e.g. a Higgsfield `generate_image` tool). Load it via ToolSearch if deferred.
2. Generate at the widest supported aspect ratio (target 21:9 / 16:9). Produce 1–2 options.

## Step 4 — Wire back & hand off
- Update the matching draft's front-matter: set `hero_image:` to the chosen URL and refine `hero_alt:` (descriptive, keyword-aware, <=125 chars).
- Show the user the banner + alt text.
> Banner set on the draft. Next: `/blog-json <brand-slug>`.

If no image MCP is connected, return the crafted prompt so the user can generate the banner themselves, and tell them to paste the URL into the draft's `hero_image`.
