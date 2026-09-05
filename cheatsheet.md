# Add content (ad8fd.com)

Repo root. Hugo Extended **0.165**. Theme is the `themes/PaperMod` submodule. Push `main` to publish. Do not commit `public/`.

Preview:

```bash
hugo server
```

Open http://localhost:1313/. Production omits `draft: true`. `hugo server` shows drafts.

Publish:

```bash
git add content
git status
git commit -m "…"
git push
```

GitHub Actions builds and deploys. Live: https://ad8fd.com/

---

## New post (text only)

```bash
hugo new posts/short-slug.md
```

Creates `content/posts/short-slug.md` → https://ad8fd.com/posts/short-slug/

Fill `title`, `summary`, `tags`. Leave `draft: false` when it should go live.

Example front matter:

```yaml
---
date: '2026-09-05T13:56:01-04:00'
draft: false
title: 'Additional Callsigns'
summary: "How to add your additional callsigns across the systems we use."
tags:
  - callsigns
---
```

`summary` is the card text on Home, Posts, RSS. If you leave it empty, Hugo truncates the body.

Optional on a long post: `showtoc: true` (see WXNetMan).

---

## New post with images (leaf bundle)

Images must sit in the **same folder** as `index.md`. A lone `foo.md` cannot see `foo.jpeg` next to it.

```bash
hugo new posts/short-slug/index.md
```

Then drop files in `content/posts/short-slug/`:

```
content/posts/short-slug/
  index.md
  circuit-irl.jpeg
  schematic.png
```

URL is still `/posts/short-slug/`.

In the body, use the filename only:

```markdown
![Circuit](circuit-irl.jpeg)
```

Cover block (copy from CTIA). `hidden: true` means no banner on the post or list card; the markdown image still shows.

```yaml
cover:
  image: circuit-irl.jpeg
  relative: true
  hidden: true
```

`git add` the images. They will not be in the commit if you only add the `.md`.

**Already published as `foo.md` and now you have pics:**

```bash
mkdir content/posts/foo
git mv content/posts/foo.md content/posts/foo/index.md
```

Put the images in `content/posts/foo/`. URL stays `/posts/foo/`.

---

## New DXpedition

Folder name is `place-year`. That becomes the URL and the archetype title.

```bash
hugo new dxpeditions/eleuthera-2027/_index.md
```

Creates `content/dxpeditions/eleuthera-2027/_index.md` → `/dxpeditions/eleuthera-2027/`

Replace the placeholders:

| Field | Example |
|---|---|
| `title` | Eleuthera 2027 DXpedition |
| `summary` | C6AFD, March 24–31, 2027. |
| tags | `DXpedition`, prefix (`C6`), place (`Eleuthera`) |
| Overview body | Callsign, Dates, Grid, Focus |

This `_index.md` is the trip card. It shows on **Home**, **DXpeditions**, and home **RSS**. Diary pages under it do not.

`date` on the trip index is what orders that card on Home. Set it to when you want the trip to appear, not necessarily day 1 of operating.

---

## New diary page on a trip

Same folder as the trip `_index.md`.

Text:

```bash
hugo new dxpeditions/eleuthera-2027/packing.md
```

With photos:

```bash
hugo new dxpeditions/eleuthera-2027/travel-setup/index.md
```

Then add jpegs next to that `index.md`, same as a post bundle.

URL: `/dxpeditions/eleuthera-2027/packing/`

Front matter:

```yaml
title: 'Packing'
summary: "IC-705, JUMA PA-1000+, and a 40–10m vertical in three bags."
tags:
  - C6
  - Eleuthera
```

Use the **same** prefix and place tags as the trip index. Put `planning` on pre-trip notes only (Planning, License in Hand). Do not add `DXpedition` on diary pages.

Diary pages list on the trip page. Prev/next walks **sibling diary pages**, not Posts. They do not appear on Home.

---

## Tags

Chips at the bottom of the post. Each chip is `/tags/<name>/`. No Tags item in the nav. Leave it that way.

| Tag | Put it on |
|---|---|
| `C6` (or the trip prefix) | Trip index **and** every diary page |
| `Eleuthera` (or the place) | Same |
| `DXpedition` | Trip index only |
| `planning` | Pre-trip diary only |
| Topic tags | Posts (`callsigns`, `homebrew`, `headset`, `emcomm`, `skywarn`, `wxnetman`, `hugo`, …) |

Hugo lowercases the URL (`C6` → `/tags/c6/`). Spell the chip the same way every time (`Eleuthera`, not `eleuthera-2026`).

Do not tag the page role (`recap`, `packing`, `setup`). Do not put `planning` on a how-to post.

---

## Front matter that actually changes the site

| Field | What it does |
|---|---|
| `title` | H1, tab (`Title \| AD8FD`), list card, prev/next |
| `summary` | List card and RSS description |
| `date` | Sort order on Home / lists / RSS |
| `draft: true` | Local preview only; production build skips it |
| `tags` | Chips + `/tags/…` pages |
| `cover` | Optional; see image bundle |
| `showtoc: true` | Table of contents on that page |
| `hiddenInHomeList: true` | Drop from Home (almost never) |
| `hiddenInRss: true` | Drop from RSS (almost never) |

Do not set `categories`. That taxonomy is not enabled.

---

## Where a new page shows up

| You created | Home | `/posts/` | `/dxpeditions/` | Trip page | Home RSS |
|---|---|---|---|---|---|
| `content/posts/…` | yes | yes | no | no | yes |
| `dxpeditions/<trip>/_index.md` | yes | no | yes | — | yes |
| diary page under a trip | no | no | no | yes | no |
| `about/`, `qsl/` | no | no | no | no | no |

---

## Edit About, QSL, nav

- About: `content/about/_index.md`
- QSL: `content/qsl/_index.md` — keep in sync with real calls and policy
- Nav labels and order: `hugo.yaml` → `menu.main`
- Home blurb: `hugo.yaml` → `params.homeInfoParams`

Do not `hugo new` these. They already exist.

---

## Markdown that this site cares about

**Image** (file in the same bundle folder):

```markdown
![Antenna](antenna.jpeg)
```

**External link** opens in a new tab (site layout does that). Internal links are normal markdown:

```markdown
[Planning](/dxpeditions/eleuthera-2026/planning-log/)
```

**Heading** `##` becomes the on-page headings. The list card ignores them.

---

## Dates while travelling

CI timezone is `America/New_York`. `hugo new` stamps local time with offset, e.g. `-04:00`.

If a page must sort as “today’s operating”, set `date` to that local time. Changing only the filename does nothing.

---

## Do not do these on the road

- Do not edit `themes/PaperMod`. It is a git submodule.
- Do not commit `public/` or `resources/_gen/`.
- Do not add a Tags menu item.
- Do not create a new top-level section (`content/pota/`, etc.) and expect it on Home. Home is **posts + each DXpedition `_index.md`**, from `layouts/partials/main_stream.html`. On a trip, put the write-up under `posts/` or under the current trip folder.
- Do not run `hugo` to publish. Push `main`; Actions publishes.

---

## Site will not build / page missing

| Symptom | Check |
|---|---|
| `hugo` errors about the theme | `git submodule update --init --recursive` |
| Page missing on ad8fd.com | `draft: true`, or not pushed, or Actions failed |
| Image 404 | File not next to `index.md`, or not `git add`ed. A `foo.md` post is not a bundle. |
| Wrong card text | Empty `summary` |
| Diary page on Home | It is a leaf under `dxpeditions/…`. Only the trip `_index.md` belongs on Home. |
| `/tags/planning/` mixed with a how-to | That post should not use `planning` |
| Local looks fine, live does not | Live Hugo is 0.165 Extended. Install that, not a random package. |

Clone on a new laptop:

```bash
git clone --recurse-submodules git@github.com:bbathe/bbathe.github.io.git
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```
