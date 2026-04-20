#!/usr/bin/env bash

show_deployment_status() {
  if [[ -f ".dokploy" ]]; then
    local dokploy_url
    dokploy_url=$(grep -Eo 'https?://[^"'\''[:space:]]+' .dokploy | head -n 1)

    if [[ -n "$dokploy_url" ]]; then
      printf 'Dokploy URL: %s\n' "$dokploy_url"
    else
      printf 'Found .dokploy, but no URL was detected in it.\n'
    fi

    return 0
  fi

  if [[ -f "vercel.json" || -f ".vercel/project.json" ]]; then
    if command -v vercel >/dev/null 2>&1; then
      vercel list
    else
      printf 'Found Vercel config, but the vercel CLI is not installed.\n'
    fi
  fi
}

NPM_OUT=$(bun outdated)
NPM_OUT_WITHOUT_COLORS=$(echo "$NPM_OUT" | sed 's/\x1b\[[0-9;]*m//g')

git checkout -b chore/npm-updates \
&& bun update \
&& bun i \
&& git add package.json bun.lock \
&& git commit -m 'npm updates' \
&& git push \
&& gh pr create -t "npm updates" -b "\`\`\`
$NPM_OUT_WITHOUT_COLORS
\`\`\`

@coderabbitai ignore
" \
&& sleep 5 \
&& show_deployment_status
