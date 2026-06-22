---
description: Generate a ranked shortlist of SEO blog topics for a brand, backed by Ahrefs keyword data.
---

# /blog-topics — Trending SEO Topic Finder

**Usage:** `/blog-topics <brand-slug>`
`$ARGUMENTS` — the brand slug from `/brand-analyze`.

## Step 1 — Load context
Read `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md`. If missing, tell the user to run `/brand-analyze <url>` first and stop. Use its SEO themes, collections, and audience as seeds.

## Step 2 — Pull keyword data (Ahrefs, optional)
1. If an Ahrefs MCP connector is available, ensure it's authenticated (run its `authenticate` tool and ask the user to complete OAuth once).
2. For each theme, pull keyword ideas with monthly volume, keyword difficulty (KD), and intent. Favor decent-volume + low/medium-KD keywords (the winnable zone).
3. Supplement with `WebSearch` for seasonal/trending angles (festivals, launches, current-month hooks).

## Step 3 — Rank & output
Produce **8–12 topics** sorted by opportunity (volume vs difficulty, weighted by brand fit):

| # | Working title | Primary keyword | Vol | KD | Intent | Angle | Collections to link |
|---|---|---|---|---|---|---|---|

Mark a **Top 3 recommended** with one line each on why. Every topic must map to at least one real collection from the profile.

End with:
> Pick one. Next: `/blog-write <brand-slug> "<chosen title>"`

If Ahrefs isn't available, proceed with WebSearch only and label volume/KD as `est.`.
