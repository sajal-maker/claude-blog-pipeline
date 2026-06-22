---
description: Analyze a brand website and write a reusable brand profile used by the whole blog pipeline.
---

# /brand-analyze — Reusable Brand Profile Builder

**Usage:** `/brand-analyze <url> [brand-slug]`
`$ARGUMENTS` — first token is the website URL; optional second token is the brand slug (defaults to the domain, e.g. `luxe-diamond`).

You are a brand analyst. Analyze the website and write **one reusable brand profile** that every later command (`/blog-topics`, `/blog-write`, `/blog-banner`, `/blog-json`, `/blog-score`) reads. Be accurate, not creative — this file is the single source of truth.

## Step 1 — Gather
1. Fetch the homepage with `WebFetch`. If JS-heavy/blocked, fall back to a browser MCP if available.
2. Also fetch one collection page and one product page to learn category names, **collection handles**, and price band.
3. *(Optional, if connected)* SimilarWeb for audience, Ahrefs for top organic keywords. Skip silently if unauthed.

## Step 2 — Extract
Capture these (write `UNKNOWN` rather than guessing):
- Brand name, domain, tagline/positioning, one-line value prop
- Target audience; **AOV tier** → `premium` if high AOV (this flips on the no-offer-language rule downstream), else `standard`
- Brand voice (3–5 adjectives) + a 2-sentence sample in that voice
- **Brand colors** as exact hex (`accent`, `lightTint`, `darkPanel`) from CSS/inline styles. If none found, estimate and mark `~approx`.
- Categories + exact **collection handles** seen in URLs. Note the site's link pattern.
- Author/journal name; whether a `/blog` section exists
- 5–8 SEO themes the brand should own
- 2–3 competitors

## Step 3 — Write the profile
Write to `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md` (create folders if missing):

```markdown
---
brand: <Name>
slug: <brand-slug>
domain: <domain>
aov_tier: premium | standard
source_url: <url>
---

# <Name> — Brand Profile

**Positioning:** ...
**Audience:** ...
**Voice:** adj, adj, adj — _"sample sentence."_

## Colors (exact hex — reuse everywhere)
- accent: `#......`
- lightTint: `#......`
- darkPanel: `#......`

## Collections (always link as `/collections/<handle>`)
- <label> -> `<handle>`

## Author / Journal
- by: <name>  | blog path exists: yes/no

## SEO themes to own
- ...

## Competitors
- ...

## Notes / UNKNOWNs
- ...
```

## Step 4 — Hand off
Print a 6-line summary and end with:
> Profile saved to brand-profiles/<slug>.md. Next: `/blog-topics <slug>`

**Carried rules:** reuse brand hex verbatim; internal links are always `/collections/<handle>` (translate `/category-view/` etc. at ingestion); never invent handles — only ones you actually saw.
