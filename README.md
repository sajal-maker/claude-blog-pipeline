# blog-pipeline

A Claude Code plugin: six chained slash commands that turn any brand website into a publish-ready, SEO-optimized blog.

```
/brand-analyze <url>   ->  writes a reusable brand profile
/blog-topics <brand>   ->  ranked SEO topic ideas (Ahrefs + web search)
/blog-write <brand> "<topic>"  ->  full article + meta, slug, alt text
/blog-banner <brand> "<topic>" ->  hero banner image (Higgsfield)
/blog-json <brand>     ->  publish-ready CMS blog JSON
/blog-score <brand>    ->  SEO score 0-100 + infographic
```

## How it works

Step 1 writes a **brand profile** (colors, voice, collections, SEO themes) to
`~/.claude/blog-pipeline/brand-profiles/<slug>.md`. Every later command reads that
profile, so the whole chain stays on-brand. Drafts are saved to
`~/.claude/blog-pipeline/blog-drafts/`. Nothing is published live — `/blog-json`
outputs JSON for you to paste into your CMS.

## Install (for your team)

**Easiest — one line in PowerShell** (copies the 6 commands into `~/.claude/commands`):

```powershell
irm https://raw.githubusercontent.com/sajal-maker/claude-blog-pipeline/main/install.ps1 | iex
```

If the repo is **private**, the raw one-liner above can't read it — clone instead:

```powershell
git clone https://github.com/sajal-maker/claude-blog-pipeline.git "$env:TEMP\bp"
Copy-Item "$env:TEMP\bp\commands\*.md" "$env:USERPROFILE\.claude\commands\" -Force
```

Then **restart Claude Code**. The six commands appear as `/brand-analyze`, `/blog-topics`, etc.

> Each command is self-contained, so the copy-into-commands method is all you need.
> `reference/blog-components.md` is bundled documentation for the JSON schema.

## Optional connectors

- **Ahrefs** — real keyword volume/difficulty in `/blog-topics` (one-time OAuth on first run; falls back to web search if absent).
- **Higgsfield image MCP** — banner generation in `/blog-banner`.

Both are optional; the commands degrade gracefully without them.

## Conventions baked in

- All internal links use `/collections/<handle>` (never `/category-view/`).
- No `headingLevel` prop in generated JSON.
- Two-tier headings only (title+subtitle OR eyebrow+title, never all three).
- Reuse exact brand hex values from the profile.
- Premium brands (high AOV): no discount/offer language.

## License

Internal use.
