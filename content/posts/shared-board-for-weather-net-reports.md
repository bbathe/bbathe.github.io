---
date: '2026-08-26T20:21:00-05:00'
draft: false
title: "A Shared Board for Weather Net Reports"
summary: "I built WXNetMan for Warren County AuxComm weather nets: a shared board so the team can see report status without changing the radio side."
tags:
  - skywarn
  - emcomm
  - wxnetman
  - serverless
---

I've been doing AuxComm in Warren County, Ohio for a while now. On a busy Weather net, Net Control is on the radio and the rest of us are trying to remember which reports are new, who is working which one, and what already went to NWS or the county EMA.

Paper logs, spreadsheets, and chat threads can work when things are slow, but they fall apart fast when reports come in faster than one person can type. We'd end up with two people on the same report, or nobody on it because everyone assumed someone else had it. I also wasn't happy with what we were sending to NWS and the county EMA. I wanted it checked, assigned, and actually finished, not a pile of duplicates.

I've been writing software for a long time, and this is basically a tracking problem with a radio in front of it. So I built [WXNetMan](https://wxnetman.com).

The radio side of the net doesn't change. Net Control still takes traffic, operators still look at a report before it goes anywhere, and I just put a board in the browser so everyone can see the same thing without asking for another read-back.

## On the net

A report starts as **New** when someone logs it, usually Net Control. An operator *takes* it, it moves to **Working**, and they check the details and leave notes. Other people can read it, but they can't take it over. When they're done it goes **Completed** and that record stays. They can leave it on the board only, send it to email, Slack, Discord, or Teams that we set up ahead of time, or note that it went out some other way, like Spotter Network, a phone call, or an office web form. If they send it, "sent" means the other end accepted the message, not that a person actually read it. If one destination fails, the report still finishes and we still try the others.

That's the whole workflow: New, Working, Completed. It's how we already thought about the work.

The roles follow the jobs on the net. Net Manager sets up the organization: people, the questions on the report form, destinations, notices. They can open and close a net and move a report if it needs a different assignee. Net Control is on the radio, can open and close, and can reassign. Operators take reports, check them, and finish them. Agency Viewer is for a partner on a wall display, counts and high-priority items, without notes or the ability to send anything.

One login per person. If you belong to more than one county, you pick the organization after you sign in. Display names and roles are per organization.

There's no public sign-up. I set the organization up first, then invite the first Net Manager. From there people sign in at [app.wxnetman.com](https://app.wxnetman.com).

## Exercises and outages

We run exercises on the same board. It's the full workflow, but nothing actually goes out to partners, and the open/close notices don't go out either. When a real net closes, Net Manager and Net Control can download a package from History with a short brief, the comms and activity logs, and the source records. That's a lot better than trying to reconstruct the night from Discord the next morning.

If the cell network drops mid-net, you can still enter **new** reports on that phone. They stay on the device and send when service comes back. Taking, editing, and finishing still need a live connection. I didn't try to make an offline copy of the whole net.

Open and close notices are a separate list from where finished reports go. A start notice can include a wall-display link, and a close notice has a traffic summary. If a notice fails, the net still opened or closed.

## The stack

I didn't want a PC sitting in somebody's shack that they'd have to patch during a storm. It's serverless on AWS, and the team just uses a browser.

Frontend is a **Next.js** static export on **S3** behind **CloudFront**. **TanStack Query** for server state, with query keys scoped by org so you don't leak another county into the UI. **WebSockets** for the live board, with polling if that falls over. **IndexedDB** on the client for those new reports when the link drops. I use it on a phone in the field and on a desktop at home, same app.

Backend is **Go** on **Lambda**. REST for CRUD, the workflow, org admin, and exports, plus separate handlers for WebSocket connect/disconnect and fan-out. **DynamoDB** for the org-scoped data. **Cognito** for login, email and password, invite-only. **SES** for the actual mail: invites, report emails, announcement lists.

A finished report can go to several destinations at once. Email goes through SES. Slack, Discord, and Teams are HTTPS POSTs to webhook URLs the org saved. Those URLs get an allowlist check when they're saved, and the outbound client doesn't follow redirects.

When a report moves, a broadcaster pushes an event to whoever is connected on that net. Dead connections get dropped. The UI shows live vs reconnecting so you know if you're looking at fresh state.

This isn't a replacement for Net Control on the radio. We're still taking reports on frequency. Slack isn't where we take traffic, and I can't make EMA actually read the email.

If your net has the same problem we had — AuxComm, ARES/RACES, SKYWARN — there's more at [wxnetman.com](https://wxnetman.com/), and you can [email me](https://wxnetman.com/contact.html) if you want to try it. Access is invite-only. If you're already invited, [sign in](https://app.wxnetman.com). Service status is at [uptime.wxnetman.com](https://uptime.wxnetman.com).
