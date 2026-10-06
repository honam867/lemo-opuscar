#!/usr/bin/env sh
# Generate one reference image with gpt-image (ChatGPT plan, via the Codex CLI login). No API key, no browser.
#   sh gen.sh <out.png> <WxH> "<prompt>" [ref.png ...]      generate (ref images keep the same character / style)
#   sh gen.sh --check                                         preflight: codex installed + logged in
# Env: CODEX_IMAGE_MODEL forces a model. Otherwise the Codex default is tried first and, if a ChatGPT login
# rejects it, each model in $CODEX_HOME/models_cache.json in turn.
set -eu
CH=${CODEX_HOME:-$HOME/.codex}

check() {
  command -v codex >/dev/null || { echo "MISSING_CODEX: needs Node.js, then: npm i -g @openai/codex ; codex login" >&2; return 1; }
  timeout 30 codex login status </dev/null 2>&1 | grep -qi 'logged in' || { echo "NOT_LOGGED_IN: run: codex login (sign in with the ChatGPT account)" >&2; return 1; }
  echo "ok: $(codex --version 2>/dev/null), logged in"
}
[ "${1:-}" = "--check" ] && { check; exit $?; }

[ $# -ge 3 ] || { echo "usage: gen.sh <out.png> <WxH> \"<prompt>\" [ref.png ...] | gen.sh --check" >&2; exit 2; }
check >/dev/null

out=$1; size=$2; prompt=$3; shift 3
dir=$(dirname "$out"); name=$(basename "$out")
mkdir -p "$dir"
[ -e "$out" ] && { echo "exists: $out (pick a new name, e.g. _v2)" >&2; exit 1; }

refs=""
for r in "$@"; do
  [ -f "$r" ] || { echo "ref not found: $r" >&2; exit 1; }
  refs="$refs -i $(cd "$(dirname "$r")" && pwd)/$(basename "$r")"
done
[ -n "$refs" ] && note="Use the attached image(s) as the reference: keep the same character design, proportions, clothing, palette and drawing style." || note=""
log="$dir/.${name}.log"

run() {   # $1 = model ('' = Codex default). -i is variadic, so '--' ends it before the prompt.
  # shellcheck disable=SC2086
  codex exec --skip-git-repo-check ${1:+-m "$1"} -s workspace-write -C "$dir" $refs -- \
    "\$imagegen Generate exactly ONE image, ${size}. ${note}
${prompt}
Save it as ./${name} in the current directory. Do not create any other file. Do nothing else." </dev/null >"$log" 2>&1
}

if [ -n "${CODEX_IMAGE_MODEL:-}" ]; then
  run "$CODEX_IMAGE_MODEL" || true
else
  run "" || true
  if [ ! -f "$out" ] && grep -q 'not supported' "$log" && [ -f "$CH/models_cache.json" ]; then
    for m in $(node -e "const j=require(process.argv[1]);const a=j.models||j.data||j;(Array.isArray(a)?a:Object.values(a)).forEach(x=>console.log(x.slug||x.id||x.model))" "$CH/models_cache.json"); do
      run "$m" || true
      [ -f "$out" ] && { echo "model: $m (set CODEX_IMAGE_MODEL=$m to skip the fallback)" >&2; break; }
      grep -q 'not supported' "$log" || break
    done
  fi
fi

[ -f "$out" ] || { echo "no image; codex log:" >&2; tail -20 "$log" >&2; exit 1; }
rm -f "$log"
echo "$out"
