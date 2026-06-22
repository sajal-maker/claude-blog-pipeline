---
description: Write a complete SEO blog draft (meta, slug, keywords, internal links, alt text) for a brand topic.
---

# /blog-write — SEO Blog Writer

**Usage:** `/blog-write <brand-slug> "<topic or title>"`
`$ARGUMENTS` — brand slug, then the topic/title (may be quoted).

Write a complete, SEO-ready article as a **draft file**. You write words + metadata here; you do NOT build JSON in this step.

## Step 1 — Load context
Read `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md`. Stop and point to `/brand-analyze` if missing. Pull voice, audience, colors, collections, author, and `aov_tier`.

## Step 2 — Plan
- Derive: **SEO title** (<=60 chars), **meta description** (<=155 chars, includes primary keyword), **slug** (kebab-case), primary + 3–5 secondary keywords, search intent.
- Outline H2/H3 sections that each target a keyword/question. Include a **FAQ** block (question-style H3s).
- Choose internal links: a hero CTA collection, >=2 in-body "read more" collection links, >=1 product/collection callout, related collections — all real handles from the profile.

## Step 3 — Write
- 900–1500 words unless told otherwise; brand voice from the profile.
- **Every image reference gets descriptive alt text** (keyword-aware, no "image of").
- **Every internal link uses `/collections/<handle>`** — never `/category-view/`.
- If `aov_tier: premium`: **no discount/offer language** — craft-led trust signals only.

## Step 4 — Save the draft
Write to `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.md` (create folder if missing):

```markdown
---
brand: <slug>
title: <display title>
seo_title: <=60 chars
meta_description: <=155 chars
slug: <handle>
primary_keyword: ...
secondary_keywords: [..., ...]
author: <from profile>
category: <label>
hero_image: TBD
hero_alt: <alt text>
collections:
  hero_cta: <handle>
  read_more: [<handle>, <handle>]
  related: [<handle>, <handle>, <handle>]
product_images: []
faq:
  - q: ...
    a: ...
---

# <Title>

<full article body: intro, H2/H3 keyword sections, inline "read more ->
/collections/<handle>" callouts, a product callout, FAQ section, author sign-off>
```

## Step 5 — Hand off
Print the meta block for review, then:
> Draft saved. Next: `/blog-banner <brand-slug> "<title>"`, then `/blog-json <brand-slug>`.

**Carried rules:** no `headingLevel` anywhere; two-tier headings only (title+subtitle OR eyebrow+title, never all three); reuse exact brand hex; deliver complete output, don't just describe.
