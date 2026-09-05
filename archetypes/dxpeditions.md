{{- if eq .File.TranslationBaseName "_index" -}}
---
date: '{{ .Date }}'
draft: false
title: '{{ replace (path.Base .File.Dir) "-" " " | title }} DXpedition'
summary: "CALL, Month DD–DD, YYYY."
tags:
  - DXpedition
  - PREFIX
  - Place
---

## Overview

My YYYY DXpedition to **Place**.

- **Callsign:**
- **Dates:**
- **Grid:**
- **Focus:**
{{- else -}}
---
date: '{{ .Date }}'
draft: false
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
summary: ""
tags:
  - PREFIX
  - Place
---
{{- end }}
