---
name: mms-deploy
description: Publish the blog to https://constantine2nd.github.io by pushing main, then confirm GitHub Pages built it and the changed pages are live. Use when the user asks to deploy, publish, push the site live, or "ship it".
---

# Deploy

GitHub Pages builds this site from `main` (legacy build, no workflow), so deploying is a push. `deploy.sh` (next to this file) wraps it.

1. Run `bash .claude/skills/mms-deploy/deploy.sh check`. It changes nothing: it stops if the tree is dirty, the branch is not `main`, or `main` is behind `origin`; lists the commits and files that would go out; warns about posts dated in the future (Pages builds without `--future` and leaves them out); and builds the site in Docker without `--future`, as Pages does. Exit code 3 means there is nothing to deploy.
2. Show the user the commit list. A push is public and the site is indexed, so get a yes before pushing unless the user's own request already named this deploy. If the list holds commits the user may not expect (not made in this conversation), name them and ask regardless. Relay any warning from the check.
3. Run `bash .claude/skills/mms-deploy/deploy.sh push`. It repeats the check, pushes, waits for the Pages build of `HEAD` (up to 15 minutes, via `gh api`), and checks the changed post URLs and the homepage return 200. Run it in the background if the wait would block other work.
4. Report the live URL of each changed post. If a cover image (`img:`) changed, say that LinkedIn and other link previews keep the old image until their cache expires (LinkedIn's Post Inspector refreshes it).

If the user has not looked at a visual change yet, offer the `mms-preview` skill first.
