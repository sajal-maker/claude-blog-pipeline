---
description: Run the entire blog pipeline end-to-end in one command — analyze brand, find a topic, write, banner, build JSON, and score.
---

# /blog-auto — Full Blog Pipeline (one shot)

**Usage:** `/blog-auto <url> [topic]`
`$ARGUMENTS` — first token is the brand website URL; everything after it (optional) is the topic. If no topic is given, auto-pick the top SEO topic.

Run all six phases **in order, automatically**. Print a short `=== Phase N ===` banner before each. Pass each phase's output to the next. Do NOT stop between phases unless a phase truly cannot proceed (e.g. the site won't load). At the very end, output the final JSON and the score.

Derive `<brand-slug>` from the domain (e.g. `luxediamond.in` -> `luxe-diamond`). Storage: profiles in `~/.claude/blog-pipeline/brand-profiles/`, drafts in `~/.claude/blog-pipeline/blog-drafts/` (create folders as needed).

These global rules apply to every phase:
- Internal links ALWAYS `/collections/<handle>` — never `/category-view/`. Translate at ingestion.
- Never output a `headingLevel` prop.
- Max two heading tiers per section (title+subtitle OR eyebrow+title), except the blog hero.
- Reuse the EXACT brand hex from the profile everywhere.
- Premium brands (high AOV): no discount/offer language.

---

## === Phase 1: Analyze brand ===
Fetch the homepage (+ one collection + one product page) with `WebFetch`. Extract brand name, positioning, audience, AOV tier (`premium` if high AOV), voice (adjectives + sample), exact brand colors (`accent`/`lightTint`/`darkPanel` hex; mark `~approx` if estimated), category **collection handles** (exact strings from URLs), author/journal, 5–8 SEO themes, competitors. Write the profile to `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md` (front-matter with `brand, slug, domain, aov_tier` + sections for colors, collections, author, SEO themes). Print a 6-line summary.

## === Phase 2: Pick topic ===
If the user supplied a topic, use it. Otherwise: using the profile's SEO themes + collections, generate 6–10 candidate topics (use an Ahrefs MCP for volume/KD if connected, else `WebSearch` for trends labelled `est.`), rank by opportunity x brand-fit, and **auto-select the #1**. Each topic must map to at least one real collection. Announce the chosen topic + primary keyword in one line.

## === Phase 3: Write the blog ===
Write a 900–1500 word article in the brand voice. Derive: SEO title (<=60 chars), meta description (<=155 chars, includes primary keyword), kebab `slug`, primary + 3–5 secondary keywords. Structure: intro, H2/H3 keyword sections, >=2 in-body "read more -> /collections/<handle>" callouts, >=1 product callout, an FAQ block (question-style H3s), author sign-off. **Every image gets descriptive alt text.** Save to `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.md` with full front-matter (title, seo_title, meta_description, slug, keywords, author, category, hero_image: TBD, hero_alt, collections{hero_cta, read_more[], related[]}, faq[]).

## === Phase 4: Generate banner ===
Build a prompt from the brand palette (use the actual hex) + topic: wide 21:9 editorial hero, negative space on one side for a headline, no embedded text. Generate with an image-gen MCP (e.g. Higgsfield `generate_image`, widest aspect ratio). Set the draft's `hero_image` to the result URL and refine `hero_alt`. If no image MCP is connected, output the prompt and leave a placeholder — keep going.

# Phase 5: Build the JSON

Assemble the draft into blog CMS JSON.

### Wrapper
```
{ "id": "blog_<ULID>", "name": <title>, "handle": <slug>,
  "content": { "root": "page", "elements": { ... } } }
```
- URL = `/blog/<handle>`. Root element key `page`, type `Page` (NO Nav/Footer — the site shell provides them).
- `page.children` = `["hero", "article", "products"]`.
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
  - Two-column grid `minmax(0,680px) 250px`: main `<article>` + sticky `<aside>`, collapsing to one column `<980px`.
  - Order: `<header>` meta (category span, `<h1>`, byline) → intro → keyword `<h2>`/`<h3>` sections → 2+ `.read-more` callouts → 1+ `.image-callout` (product img + `<small>`) → FAQ `<h2>` with question `<h3>`s → author card → dark newsletter panel (bg = `darkPanel` hex) → aside (share links → `https://<domain>/blog/<handle>`, Popular Posts, tip card).
  - All accents/links use the `accent` hex; light fills use `tint`; dark panel uses `darkPanel`. Reuse the EXACT profile hex everywhere.

### 3. `products` — BlogSection
- Props: `layout: "grid"`, `textAlign: "left"`, `aspectRatio: "4/3"`, `sectionPadding: "sm"`, `title: "You May Also Like"`, `subtitle`, `viewAll: { href: "/blog", label }`.
- 3 items, each: `{ id, title, description, image, imageAlt, href, date, author, category }`.
  - `href` → `/collections/<handle>`. `date` = `<Brand> Journal`. `author` = `<Brand>`. `category` = a short label.
  - `description`, `date`, `author`, `category` render the card chrome — do NOT omit them or cards render bare.

### Validate before output
- `/collections/<handle>` everywhere — never `/category-view/` or `/collection-view/`.
- No `headingLevel` prop on any element.
- Exact brand hex (`accent` / `tint` / `darkPanel`) reused throughout — no near-matches.
- Descriptive `imageAlt` on every image (hero, in-article callouts, all 3 product cards).
- Each section has `"children": []` and the correct `tracking_id`.
- Valid JSON — no trailing commas, all keys in `page.children` exist in `elements`.
## === Phase 6: Score + infographic ===
Score 0–100 weighted: keyword targeting (20), meta & slug (10), structure/readability (15), internal linking (15), content depth (15), media & alt text (10), brand compliance (15). Give each dimension a score + one-line reason + the top fix if below full. If a visualization MCP is available, render an on-brand scorecard (bars in the `accent` hex, total with red/amber/green band, top-3 fixes); otherwise output a markdown table.

## === Done ===
Finish with a summary: brand, topic, slug, word count, score, and where the JSON was saved. If any phase degraded (no Ahrefs / no image MCP), note it so the user can re-run that single step manually.
