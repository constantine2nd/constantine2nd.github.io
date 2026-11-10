#!/usr/bin/env bash
# Deploy this blog: GitHub Pages builds the site from main (legacy build), so deploying is a push.
#
#   deploy.sh check   what would go out, and whether it builds; changes nothing
#   deploy.sh push    push main, wait for the Pages build of HEAD, check the changed pages are live
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
SITE="https://constantine2nd.github.io"
REPO="constantine2nd/constantine2nd.github.io"
IMAGE="jekyll/jekyll:4"
GEMS_VOLUME="claude-preview-gems"   # shared with the mms-preview skill

fail() { echo "STOP: $*" >&2; exit 1; }

changed_post_urls() {  # live URLs of posts added or changed in origin/main..HEAD (permalink is :title/)
  git diff --name-only --diff-filter=AM origin/main..HEAD -- _posts \
    | sed -E 's#^_posts/[0-9]{4}-[0-9]{2}-[0-9]{2}-(.*)\.(md|markdown|html)$#/\1/#' | grep '^/' || true
}

check() {
  [ "$(git branch --show-current)" = "main" ] || fail "not on main"
  git fetch -q origin main
  [ -z "$(git status --porcelain)" ] || { git status --short; fail "uncommitted changes; commit or discard them first"; }
  local behind ahead
  behind="$(git rev-list --count HEAD..origin/main)"; ahead="$(git rev-list --count origin/main..HEAD)"
  [ "$behind" -eq 0 ] || fail "main is $behind commit(s) behind origin/main; pull first"
  [ "$ahead" -gt 0 ] || { echo "nothing to deploy: main matches origin/main"; exit 3; }

  echo "== commits to push ($ahead)"; git log --oneline origin/main..HEAD
  echo "== files"; git diff --stat origin/main..HEAD | tail -n 25

  # Pages builds without --future: a post dated later than now is silently left out.
  local now f d late=0
  now="$(date +%s)"
  for f in $(git diff --name-only --diff-filter=AM origin/main..HEAD -- _posts); do
    d="$(sed -n '2,15{s/^date:[[:space:]]*//p}' "$f" | head -1)"
    [ -n "$d" ] || d="$(basename "$f" | cut -c1-10)"
    if [ "$(date -d "$d" +%s 2>/dev/null || echo 0)" -gt "$now" ]; then
      echo "WARN: $f is dated $d, in the future; GitHub Pages will not publish it until a later build" >&2; late=1
    fi
  done

  echo "== build (Docker, read-only repo, no --future, like Pages)"
  if ! docker run --rm -v "$PWD:/srv/jekyll:ro" -v "$GEMS_VOLUME:/usr/local/bundle" \
      --tmpfs /out --tmpfs /tmp/gf --entrypoint sh "$IMAGE" -c '
        cp /srv/jekyll/Gemfile /tmp/gf/Gemfile &&
        printf "\ngem \"csv\"\ngem \"logger\"\ngem \"base64\"\ngem \"bigdecimal\"\n" >> /tmp/gf/Gemfile &&
        export BUNDLE_GEMFILE=/tmp/gf/Gemfile && bundle install --quiet && cd /srv/jekyll &&
        bundle exec jekyll build -s /srv/jekyll -d /out --disable-disk-cache --strict_front_matter' \
      > /tmp/deploy-build.$$ 2>&1; then
    tail -n 30 /tmp/deploy-build.$$ >&2; rm -f /tmp/deploy-build.$$; fail "the site does not build"
  fi
  grep -iE "warn|error|deprecat" /tmp/deploy-build.$$ | head -n 10 || true
  rm -f /tmp/deploy-build.$$
  echo "build ok"
  [ $late -eq 0 ] || echo "check passed with warnings (see above)"
  echo "== pages to verify after deploy"; changed_post_urls | sed "s#^#$SITE#"; echo "$SITE/"
}

push() {
  check >/dev/null
  local head urls
  head="$(git rev-parse HEAD)"
  urls="$(changed_post_urls)"
  git push -q origin main
  echo "pushed $(git rev-parse --short HEAD); waiting for the Pages build..."

  local i status commit err
  for ((i = 0; i < 90; i++)); do   # up to ~15 minutes
    read -r status commit err < <(gh api "repos/$REPO/pages/builds/latest" \
      --jq '[.status, .commit, (.error.message // "-")] | @tsv' 2>/dev/null || echo "unknown - -")
    if [ "$commit" = "$head" ]; then
      case "$status" in
        built) echo "Pages build done"; break ;;
        errored) fail "Pages build failed: $err (see repo Settings > Pages)" ;;
      esac
    fi
    sleep 10
  done
  [ "$status" = "built" ] && [ "$commit" = "$head" ] || fail "no finished Pages build for $head after 15 minutes; status: $status"

  local u code ok=1
  for u in $urls /; do   # the CDN can lag the build by a minute or two
    for ((i = 0; i < 18; i++)); do
      code="$(curl -s -o /dev/null -w '%{http_code}' "$SITE$u")"
      [ "$code" = "200" ] && break; sleep 10
    done
    echo "$code $SITE$u"; [ "$code" = "200" ] || ok=0
  done
  [ $ok -eq 1 ] && echo "deployed: $SITE/" || fail "some pages are not live yet (above)"
}

case "${1:-}" in
  check) check ;; push) push ;;
  *) echo "usage: $0 check|push" >&2; exit 2 ;;
esac
