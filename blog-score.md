---
description: Score a finished blog on SEO and quality (0-100) and render an on-brand infographic scorecard.
---

# /blog-score — SEO Quality Score + Infographic

**Usage:** `/blog-score <brand-slug> [draft-slug]`
`$ARGUMENTS` — brand slug, optional draft handle. If ambiguous, list drafts and ask.

## Step 1 — Load
Read the draft `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.md` (and the `.json` if saved) plus the brand profile.

## Step 2 — Score (0–100, weighted)

| Dimension | Wt | Check |
|---|---|---|
| Keyword targeting | 20 | Primary keyword in SEO title, H1, first 100 words, >=1 H2, meta; secondary keywords present, not stuffed |
| Meta & slug | 10 | SEO title <=60, meta <=155 with keyword, clean kebab slug |
| Structure & readability | 15 | Logical H2/H3, short paragraphs, scannable |
| Internal linking | 15 | >=3 `/collections/<handle>` links, real handles, descriptive anchors |
| Content depth | 15 | 900–1500 words, answers intent, FAQ present |
| Media & alt text | 10 | Hero set, every image has descriptive alt text |
| Brand compliance | 15 | Exact brand hex, no `headingLevel`, no offer language if premium, two-tier headings |

For each dimension: score, one-line reason, and the single highest-impact fix if below full marks.

## Step 3 — Infographic
If a visualization tool is available (e.g. an MCP that renders SVG/HTML widgets), render a scorecard:
- Big total score with a color band (red <60, amber 60–79, green 80+).
- Horizontal bars per dimension (score / weight), in the **brand's accent hex**.
- A short "Top 3 fixes" list.

If no such tool is available, output the scorecard as a clean markdown table instead.

## Step 4 — Output
Below the visual, print the scored table + prioritized fix list (highest impact first). If total < 80:
> Want me to apply these fixes? I'll update the draft and re-run `/blog-json`.
