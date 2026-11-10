---
name: mms-preview
description: Run this site locally for a human to review, then remove everything the preview created. Use when the user wants to see a change rendered before it is pushed ("run the site", "preview", "let me look at it"), or after editing a post or layout when a look in the browser would catch what reading the diff cannot.
---

# Local preview

`preview.sh` (next to this file) starts, reports on, and stops a preview of the repository it runs in.

- Jekyll runs in Docker (`jekyll/jekyll:4`), because this machine has no Ruby. The repository is mounted read-only and the build goes to a tmpfs, so a preview cannot change a tracked file or leave `_site/`, `.jekyll-cache/` or a modified `Gemfile.lock` behind. Gems are cached in the Docker volume `claude-preview-gems` so later starts take seconds; the first takes a few minutes.
- `--drafts --future` are on, so drafts and posts dated ahead show up.
- Everything binds to 127.0.0.1 on the first free port from 4000 (livereload from 35729), so it can run next to other containers on this machine.
- A forgotten preview stops itself after 4 hours.

## Flow

1. Start it: `bash .claude/skills/mms-preview/preview.sh start`. It prints the URL when the site answers, or the container's last log lines if the build failed.
2. Give the user the URL of the page that changed (the `permalink` in `_config.yml` is `:title/`, so a post is at `/<slug>/`), not only the homepage. If browser tools are available, open that page and look at it yourself first, so obvious breakage is fixed before they spend time on it.
3. Wait for the user to say they are done. Edits made while they review appear on reload (livereload), so keep the preview running between fixes.
4. When they are done, stop it: `bash .claude/skills/mms-preview/preview.sh stop`. Report the last line it prints (`clean: ...` or what was left). `stop --all` also removes the gems volume; use it only when the user asks to remove everything including the cache.

Run `status` when unsure whether a preview is up. Previews started by hand or before this skill existed are not labelled and are not touched by `stop`; if one holds a port or repo you need, name it to the user and ask before removing it.
