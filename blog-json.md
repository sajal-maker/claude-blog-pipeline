---
description: Assemble a written blog draft into publish-ready CMS blog JSON (self-contained structure).
---

# /blog-json — Build Publish-Ready Blog JSON

**Usage:** `/blog-json <brand-slug> [draft-slug]`
`$ARGUMENTS` — brand slug, optional draft handle. If multiple drafts exist and none specified, list them and ask which.

Turn the written draft + banner into complete, copy-paste-ready blog CMS JSON. The blog is already written; **this step only assembles JSON** — do not rewrite the article.

## Step 1 — Load everything
1. `~/.claude/blog-pipeline/brand-profiles/<brand-slug>.md` -> colors, author, domain.
2. `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.md` -> article body, all meta, `hero_image`/`hero_alt`, collections, FAQ.
3. If `hero_image` is `TBD`, warn the user and suggest `/blog-banner` first (or proceed with a placeholder).

## Step 2 — Load the live schema reference (do this first)
Fetch the latest schema + rules with `WebFetch` from:
`https://raw.githubusercontent.com/sajal-maker/claude-blog-pipeline/main/reference/blog-components.md`
This is the **single source of truth** — follow it exactly; do not invent props. If the fetch fails (offline/URL down), fall back to the inlined summary below.

## Step 3 — Assemble (blog JSON structure)
Build this structure:

- **Wrapper:** `{ "id": "blog_<ULID>", "name": <title>, "handle": <slug>, "content": { "root": "page", "elements": { ... } } }`. Blog URL = `/blog/<handle>`.
- **Root** element type `Page` (key `"page"`). **No Nav/Footer** — the site shell provides them.
- **Three children**, each with a `tracking_id`:
  1. `hero` (`tracking_id: blog_article_hero`) — ContentSection variant `text-over-image`, `aspectRatio: "21/9"`, `sectionPadding: "hero"`. Item: badge + eyebrow + title + subheading + byline-HTML description + CTA -> hero collection. (The two-tier heading rule does NOT apply to the blog hero.)
  2. `article` (`tracking_id: blog_article_body`) — ContentSection variant `simple`, `textAlign: "left"`, `sectionPadding: "sm"`. One item whose `description` is the **full HTML article**: an inline `<style>` block with brand-prefixed scoped classes (use the brand hex), a two-column grid (~680px article + ~250px sticky aside, collapsing below 980px), header meta, H2/H3 keyword sections, >=2 "read more" collection callouts, >=1 product callout with caption, an FAQ block of question-style H3s, an author card, a dark newsletter CTA panel (use `darkPanel` hex), and an aside with share links (`https://<domain>/blog/<handle>`). Convert the markdown body into this HTML.
  3. `products` (`tracking_id: blog_you_may_also_like`) — BlogSection variant `grid`, `aspectRatio: "4/3"`, title "You May Also Like", `viewAll` -> `/blog`, 3 items each -> `/collections/<handle>` with real product images.

## Step 4 — Validate before output (NON-NEGOTIABLE)
- Every link uses `/collections/<handle>` — no `/category-view/`.
- **No `headingLevel`** anywhere — search the output for `"headingLevel"` and remove it.
- Reuse the **exact** brand hex from the profile (no near-matches).
- Every image has alt text.
- Valid JSON (no trailing commas, balanced braces).

## Step 5 — Output
Print the **complete JSON** in one block (never partial). Optionally save to `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.json`.
> JSON ready to paste into the CMS. Next: `/blog-score <brand-slug>`.

---

## Component prop schema (use ONLY these props — do not invent others)

### ContentSection (hero + article)
`items: ContentItem[]` where each item = `{ id, title, description, image, imageAlt?, badge?, eyebrow?, subheading?, cta?, secondaryCta?, backgroundColor?, textColor?, aspectRatio? }`
Section props: `layout` (use `text-over-image` for hero, `simple` for article; `variant` is an alias), `title`, `subtitle`, `aspectRatio` (e.g. `21/9`), `imageRatio` (`25:75`..`75:25`), `imageSide` (`left`/`right`), `textAlign`, `backgroundColor`, `textColor`, `container` (default true).
- `item.cta.url` is normalized to `item.cta.href` — prefer `href`.

### BlogSection (related products)
`items: BlogItem[]` where each item = `{ id, title, image, imageAlt?, description?, href?, date?, author?, category? }`
Section props: `layout` (use `grid`), `title`, `subtitle`, `aspectRatio` (e.g. `4/3`), `textAlign`, `navigation` (`arrows`/`none`), `viewAll: { href, label }`.
- The component lists a `headingLevel` prop, but **never set it** (it breaks rendering).

(A human-readable copy also lives in `reference/blog-components.md` in the repo.)
