#!/bin/sh

NPM_OUT=$(npm outdated --json); \
JSON_WITHOUT_EXTRA_KEYS=$(echo "$NPM_OUT" | jq 'map_values(del(.dependent, .location))')
git checkout -b chore/npm-updates \
&& npm update \
&& git add package.json package-lock.json \
&& git commit -m 'npm updates' \
&& git push \
&& gh pr create -B staging -t "npm updates" -b "\`\`\`json 
$(echo "$JSON_WITHOUT_EXTRA_KEYS") 
\`\`\`"
