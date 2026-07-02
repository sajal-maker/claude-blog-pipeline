---
description: Run the entire blog pipeline end-to-end in one command — analyze brand, find a topic, write, build JSON, and score.
---

# /blog-auto — Full Blog Pipeline (one shot)

**Usage:** `/blog-auto <url> [topic]`
`$ARGUMENTS` — first token is the brand website URL; everything after it (optional) is the topic. If no topic is given, auto-pick the top SEO topic.

Run all five phases **in order, automatically**. Print a short `=== Phase N ===` banner before each. Pass each phase's output to the next. Do NOT stop between phases unless a phase truly cannot proceed (e.g. the site won't load). At the very end, output the final JSON and the score.

Derive `<brand-slug>` from the domain (e.g. `luxediamond.in` -> `luxe-diamond`). Storage: profiles in `~/.claude/blog-pipeline/brand-profiles/`, drafts in `~/.claude/blog-pipeline/blog-drafts/` (create folders as needed).

## Required inputs per brand

Some values CANNOT be derived from the website — collect them before Phase 5 (ask once, together, if missing):

| Input | Source | Needed for |
|-------|--------|-----------|
| `store_id` (`store_...` ULID) | **user must provide** | wrapper `store_id`, product image URL paths |
| Storefront domain | URL argument | share links, canonical blog URL |
| Hero image URL | **user must provide** (no image generation in this pipeline) | hero `image`, `metadata.seo.ogImage`, `metadata.featuredImage` |
| Product image URLs (1 in-article + 3 related cards) | store CMS/media (`media.alippo.com/media/<store_id>/...`) or user | image callout + related cards |
| Collection handles (exact strings) | derived in Phase 1, verify against live URLs | hero CTA, read-more callouts, newsletter CTA, related cards |
| Brand colors (`accent` / `lightTint` / `darkPanel` / `button` hex) | derived in Phase 1; user confirms if `~approx` | article `<style>`, hero card |
| Author/journal name, category label, publish date | derived or ask | byline, metadata |
| Topic + primary keyword | argument or Phase 2 | everything |

These global rules apply to every phase:
- Internal links ALWAYS `/collections/<handle>` — never `/category-view/`. Translate at ingestion.
- Never output a `headingLevel` prop.
- Max two heading tiers per section (title+subtitle OR eyebrow+title), except the blog hero.
- Reuse the EXACT brand hex from the profile everywhere.
- Premium brands (high AOV): no discount/offer language.

---

## === Phase 1: Analyze brand ===
Fetch the homepage (+ one collection + one product page) with `WebFetch`. Extract brand name, positioning, audience, AOV tier (`premium` if high AOV), voice (adjectives + sample), exact brand colors (`accent`/`lightTint`/`darkPanel`/`button` hex; mark `~approx` if estimated), category **collection handles** (exact strings from URLs), author/journal, 5–8 SEO themes, competitors. Write the profile to `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md` (front-matter with `brand, slug, domain, store_id, aov_tier` + sections for colors, collections, author, SEO themes; `store_id: TBD` if the user hasn't given it yet). Print a 6-line summary.

## === Phase 2: Pick topic ===
If the user supplied a topic, use it. Otherwise: using the profile's SEO themes + collections, generate 6–10 candidate topics (use an Ahrefs MCP for volume/KD if connected, else `WebSearch` for trends labelled `est.`), rank by opportunity x brand-fit, and **auto-select the #1**. Each topic must map to at least one real collection. Announce the chosen topic + primary keyword in one line.

## === Phase 3: Write the blog ===
Write a 900–1500 word article in the brand voice. Derive: SEO title (<=60 chars), meta description (<=155 chars, includes primary keyword), kebab `slug`, primary + 3–5 secondary keywords. Structure: intro, H2/H3 keyword sections, >=2 in-body "read more -> /collections/<handle>" callouts, >=1 product callout, an FAQ block (5 question-style H3s), author sign-off. **Every image gets descriptive alt text.** Save to `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.md` with full front-matter (title, seo_title, meta_description, slug, keywords, author, category, publish_date, hero_image, hero_alt, collections{hero_cta, read_more[], related[]}, faq[]).

**Hero image:** this pipeline does NOT generate images. Use the hero image URL provided by the user; if none was given, set `hero_image: PLACEHOLDER`, note it in the final summary, and keep going.

# Phase 4: Build the JSON

Assemble the draft into blog CMS JSON, matching the canonical template export structure exactly (reference: `samika-blog-topic-templates-current-20260702.docx`).

### Wrapper (full DB-row shape)
```
{
  "id": "blog_<ULID>",
  "store_id": "<store_id>",
  "name": "<title>",
  "slug": "/blog/<slug>",
  "entity_type": "blog",
  "route_prefix": "/blog/<slug>",
  "spec": { "root": "page", "elements": { ... } },
  "metadata": { ... },
  "_status": "published",
  "created_at": "<ISO now>",
  "updated_at": "<ISO now>",
  "deleted_at": null
}
```
- `slug` and `route_prefix` are IDENTICAL and both carry the `/blog/` prefix. `metadata.slug` is the BARE slug (no prefix) — this is the only bare occurrence.
- `spec.root` = `"page"`. Root element key `page`, type `Page`, props `{}` (NO Nav/Footer — the site shell provides them).
- `page.children` = `["hero", "article", "products"]` — always wire all three (the Samika export left `products` orphaned in 2 of 3 templates; that was a defect, don't copy it).
- Every section element carries `"children": []` AND a `tracking_id`. The element KEY and the `tracking_id` are different strings — do not reuse the key:

| Element key | type | tracking_id |
|-------------|------|-------------|
| `hero` | ContentSection | `blog_article_hero` |
| `article` | ContentSection | `blog_article_body` |
| `products` | BlogSection | `blog_you_may_also_like` |

### 1. `hero` — ContentSection
- Props: `layout: "text-over-image"`, `aspectRatio: "21/9"`, `sectionPadding: "hero"`.
- Single item: `{ id, badge, eyebrow, title, subheading, description, cta, image, imageAlt, textColor, backgroundColor }`.
  - `title` = SEO question-style H1. `subheading` = one-liner.
  - `description` = **byline HTML only**, e.g. `<p><strong><Brand> Journal</strong> · <Date></p>` — not prose.
  - `backgroundColor` = semi-transparent rgba over the image (e.g. `rgba(255,248,251,.88)`) + `textColor` for legibility. **Both are required here.**
  - `cta.href` → a `/collections/<handle>`. Use `cta.href`, never `cta.url`.
- **Exempt from the 2-tier heading rule.** badge + eyebrow + title + subheading + description on the hero is intentional — do NOT strip tiers.

### 2. `article` — ContentSection
- Props: `layout: "simple"`, `textAlign: "left"`, `sectionPadding: "sm"`.
- Single item = `{ id, description }` only. `description` is the FULL HTML article:
  - Inline `<style>` with **brand-scoped class prefix** (`.<brand>-*`) so styles never collide.
  - Two-column grid `minmax(0,680px) 250px`, gap 42px: main `<article>` + sticky `<aside>` (`top:82px`, left border), collapsing to one column `<980px` via a single `@media` block.
  - Order inside `<article>`: `<header>` meta (category span, `<h1>`, byline) → intro paragraphs → keyword `<h2>`/`<h3>` sections → 2+ `.read-more` callouts → 1+ `.image-callout` (product img + `<small>` caption) → FAQ `<h2>` with 5 question `<h3>`s → author card (circle monogram + journal name) → dark newsletter panel (bg = `darkPanel` hex, button = `button` hex).
  - `<aside>` order: share links fb/x/wa (absolute `https://<domain>/blog/<slug>` URLs — always the brand's real domain) → Popular Posts (4 links) → brand tip card.
  - All accents/links use the `accent` hex; light fills use `lightTint`; dark panel uses `darkPanel`. Reuse the EXACT profile hex everywhere.

### 3. `products` — BlogSection
- Props: `layout: "grid"`, `textAlign: "left"`, `aspectRatio: "4/3"`, `sectionPadding: "sm"`, `title: "You May Also Like"`, `subtitle`, `viewAll: { href: "/blog", label }`.
- 3 items, each: `{ id, title, description, image, imageAlt, href, date, author, category }`.
  - `href` → `/collections/<handle>` or another `/blog/<slug>`. `date` = `<Brand> Journal`. `author` = `<Brand>`. `category` = a short label.
  - `description`, `date`, `author`, `category` render the card chrome — do NOT omit them or cards render bare.

### 4. `metadata`
```
{
  "seo": { "ogImage": <hero image URL>, "keywords": [primary + secondary],
           "metaTitle": "<Title> | <BRAND>", "metaDescription": <=155 chars },
  "slug": "<bare slug>",
  "category": "<category label>",
  "updatedBy": "claude",
  "readingTime": "<N> min read",
  "contentFormat": "storefront-component-json",
  "featuredImage": { "alt": <hero imageAlt>, "url": <hero image URL> }
}
```
`ogImage`, `featuredImage.url`, and the hero item `image` are the SAME URL.

### Validate before output
- `/collections/<handle>` everywhere — never `/category-view/` or `/collection-view/`.
- No `headingLevel` prop on any element.
- Exact brand hex (`accent` / `lightTint` / `darkPanel` / `button`) reused throughout — no near-matches.
- Descriptive `imageAlt` on every image (hero, in-article callouts, all 3 product cards).
- Each section has `"children": []` and the correct `tracking_id`; `page.children` lists all three and every child key exists in `elements`.
- `slug` == `route_prefix` (both `/blog/...`); `metadata.slug` is bare; `store_id` present and matches the profile.
- Share links use the brand's real domain.
- Valid JSON — no trailing commas.

## === Phase 5: Score + infographic ===
Score 0–100 weighted: keyword targeting (20), meta & slug (10), structure/readability (15), internal linking (15), content depth (15), media & alt text (10), brand compliance (15). Give each dimension a score + one-line reason + the top fix if below full. If a visualization MCP is available, render an on-brand scorecard (bars in the `accent` hex, total with red/amber/green band, top-3 fixes); otherwise output a markdown table.

## === Done ===
Finish with a summary: brand, topic, slug, word count, score, and where the JSON was saved. List any placeholders left (hero image, store_id) so the user can fill them before publishing. If any phase degraded (no Ahrefs), note it so the user can re-run that single step manually.
