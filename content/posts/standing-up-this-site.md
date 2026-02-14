---
date: '2025-12-22T11:40:15-05:00'
draft: false
title: 'Standing Up This Site'
summary: "How I’m hosting my amateur radio stories using a static site stack instead of a generic blog platform."
tags:
  - hugo
  - github-pages
  - papermod
---

I wanted a home for my amateur radio stories that was:

- Fast and simple
- Text-first, with a few photos
- Version-controlled like code
- Cheap and low-maintenance

So instead of spinning up WordPress or using a hosted blog platform, I went with a static site stack:

- **Hugo** as the static site generator
- **PaperMod** as the theme
- **GitHub Pages** for hosting
- **Git** as the publishing workflow

## Why Hugo?

Hugo is a static site generator written in Go. It takes Markdown files and template files and turns them into a plain HTML site.

What I like for this use case:

- Content is just **Markdown files in a repo**.
- Builds are **fast**.
- It handles sections nicely:
  - `/dxpeditions/eleuthera-2026/`
  - `/posts/`
  - `/about/`
- Easy to keep things organized by trip, date, and type.

## Why PaperMod?

PaperMod is a minimalist Hugo theme with:

- Clean typography
- Simple, readable post layout
- Light theme that feels optimistic and uncluttered

I didn’t want a heavy “portfolio” theme or a dark, terminal-like look. PaperMod is right in the middle: simple, modern, no nonsense.

## Why GitHub Pages?

GitHub Pages gives me:

- Free hosting for a static site
- Automatic builds via **GitHub Actions**
- A natural workflow:
  - `git commit`
  - `git push`
  - site updates

There’s no database, no patching, no admin UI to babysit. Everything that matters lives in the repo.
