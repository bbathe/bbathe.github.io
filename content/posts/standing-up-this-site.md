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

I wanted a home for my amateur radio stories that was fast, mostly text with a few pics, version-controlled like code, and cheap to keep running.

So I skipped WordPress. The stack is:

- **Hugo** as the static site generator
- **PaperMod** as the theme
- **GitHub Pages** for hosting
- **Git** as the publishing workflow

Hugo is written in Go. Markdown and templates in, HTML out. Content is just files in a repo, builds are fast, and I can keep sections straight:

- `/dxpeditions/eleuthera-2026/`
- `/posts/`
- `/about/`

PaperMod is a simple theme. Clean type, readable posts. I didn't want a heavy portfolio look or a dark terminal look.

GitHub Pages is free, GitHub Actions builds it, and the workflow is `git commit`, `git push`, site updates. No database, no patching, no admin UI to babysit. Everything that matters lives in the repo.
