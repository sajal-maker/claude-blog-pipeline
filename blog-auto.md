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

## === Phase 5: Build the JSON ===
Assemble the draft into blog CMS JSON. Structure:
- Wrapper `{ "id": "blog_<ULID>", "name": <title>, "handle": <slug>, "content": { "root": "page", "elements": {...} } }`; URL `/blog/<handle>`; root type `Page` (no Nav/Footer).
- 3 children with tracking_ids: `hero` (ContentSection `text-over-image`, `aspectRatio: "21/9"`, `sectionPadding: "hero"`), `article` (ContentSection `simple`, `textAlign: "left"`, `sectionPadding: "sm"`; its `description` is the full HTML article — inline brand-scoped `<style>`, two-column 680px + 250px sticky aside collapsing <980px, H2/H3 sections, read-more + product callouts, FAQ, author card, dark newsletter panel using `darkPanel` hex, aside share links to `https://<domain>/blog/<handle>`), and `products` (BlogSection `grid`, `aspectRatio: "4/3"`, title "You May Also Like", `viewAll` -> `/blog`, 3 items -> `/collections/<handle>`).
- ContentSection items: `{ id, title, description, image, imageAlt?, badge?, eyebrow?, subheading?, cta?, aspectRatio? }`; `cta.href` not `cta.url`. BlogSection items: `{ id, title, image, imageAlt?, href }`. Use ONLY these props.
- Validate: `/collections/<handle>` everywhere, no `headingLevel`, exact brand hex, alt text on every image, valid JSON. Print the COMPLETE JSON in one block and save to `~/.claude/blog-pipeline/blog-drafts/<brand-slug>__<slug>.json`.

## === Phase 6: Score + infographic ===
Score 0–100 weighted: keyword targeting (20), meta & slug (10), structure/readability (15), internal linking (15), content depth (15), media & alt text (10), brand compliance (15). Give each dimension a score + one-line reason + the top fix if below full. If a visualization MCP is available, render an on-brand scorecard (bars in the `accent` hex, total with red/amber/green band, top-3 fixes); otherwise output a markdown table.

## === Done ===
Finish with a summary: brand, topic, slug, word count, score, and where the JSON was saved. If any phase degraded (no Ahrefs / no image MCP), note it so the user can re-run that single step manually.
