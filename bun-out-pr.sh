#!/usr/bin/env bash

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
&& vercel ls

