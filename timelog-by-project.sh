#!/bin/bash
#
# timelog-by-project.sh — Chunk a timelog.txt (see commit-timelog.sh) into
# billable projects using a folder→project key file.
#
# Output (default ./timelog-by-project.txt) keeps the exact same commit line
# format as the input, but groups commits by day (newest first), and within
# each day by project (alphabetically). Each project header shows that day's
# commit count for the project:
#
#   ===== 2026-05-30 =====
#
#   Willow Creek App (20)
#   2026-05-30 13:33  blackthorn-software/crewview-rn  Update i18n count
#   2026-05-30 13:25  blackthorn-software/crewview-rn  fix: PR feedback
#
#   WWC Manager (4)
#   2026-05-30 12:31  wasatch/wwc-manager  ...
#
# Within each day, repos in no key are grouped under "Unmatched" and repos
# listed as "ignore" in the key under "Ignored" — both sorted last so nothing
# billable slips through unnoticed.
#
# Key file format (see timelog-projects-key.txt):
#   # comments and blank lines are ignored
#   folder-name : Project Name
#   other-folder : ignore
# A key matches a repo when the key's folder string appears (case-insensitively,
# ignoring hyphens) in ANY segment of the repo's path — so
# `denverwindowwellcovers` matches `wasatch/denverwindowwellcovers-astro`,
# `crew-view` matches `crewview-rn`, and a parent-directory key like
# `non-billable-projects : ignore` matches every repo beneath that folder. When
# several keys match, the longest (most specific) wins.

set -euo pipefail

# --- Config -----------------------------------------------------------------
INPUT='timelog.txt'                  # produced by commit-timelog.sh
KEY='timelog-projects-key.txt'       # folder → project mapping
OUTPUT='timelog-by-project.txt'
# ----------------------------------------------------------------------------

if [[ ! -f "$INPUT" ]]; then
  echo "Input not found: $INPUT (run commit-timelog.sh first)" >&2
  exit 1
fi
if [[ ! -f "$KEY" ]]; then
  echo "Key file not found: $KEY" >&2
  exit 1
fi

TAB=$'\t'
sorted="$(mktemp)"
trap 'rm -f "$sorted"' EXIT

# Stage 1: tag every commit line with a composite sort key + display project.
# Emits 5 tab-separated fields:
#   <comp(date)> <project-sort-key> <comp(timestamp)> <commit line> <display project>
# comp() is the 9's-complement of each digit, so a plain ASCENDING sort of the
# complemented date/time yields DESCENDING (newest-first) order — this avoids
# BSD sort's unreliable mixed asc/desc per-key modifiers.
awk '
  function comp(s,   i, c, o) {           # 9s-complement of digits -> reverse sort
    o = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      o = o ((c >= "0" && c <= "9") ? (9 - c) : c)
    }
    return o
  }

  # --- key file (read first) ---
  FNR == NR {
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*#/ || line ~ /^[[:space:]]*$/) next
    ci = index(line, ":")                 # split on the FIRST colon only
    if (ci == 0) next
    folder = substr(line, 1, ci - 1)
    proj   = substr(line, ci + 1)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", folder)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", proj)
    if (folder == "") next
    nkeys++
    kfolder = tolower(folder); gsub(/-/, "", kfolder)   # hyphen-insensitive
    kf[nkeys] = kfolder
    kp[nkeys] = (tolower(proj) == "ignore") ? "@IGNORE" : proj
    next
  }

  # --- timelog file ---
  length($0) < 19 { next }                # skips blank date-separator lines too
  {
    cdate = comp(substr($0, 1, 10))       # date, reverse-sorted
    cts   = comp(substr($0, 1, 16))       # full timestamp, reverse-sorted
    rest  = substr($0, 19)                # commit line is fixed-width
    di    = index(rest, "  ")
    repo  = (di > 0) ? substr(rest, 1, di - 1) : rest
    n = split(repo, parts, "/")

    # Test every path segment (parent dirs and the leaf), so a directory-level
    # key like `non-billable-projects : ignore` matches every repo beneath it.
    # Longest matching key across all segments wins.
    bestlen = 0; bestproj = ""
    for (s = 1; s <= n; s++) {
      seg = tolower(parts[s]); gsub(/-/, "", seg)       # hyphen-insensitive
      for (i = 1; i <= nkeys; i++) {
        if (index(seg, kf[i]) > 0 && length(kf[i]) > bestlen) {
          bestlen = length(kf[i]); bestproj = kp[i]
        }
      }
    }
    # Field 2 carries a rank prefix (0 projects, 1 Unmatched, 2 Ignored) so the
    # two catch-all groups sort last — a numeric prefix avoids the locale quirk
    # where punctuation sentinels collate before letters under BSD sort.
    if (bestlen > 0 && bestproj == "@IGNORE")
         { print cdate "\t2 Ignored\t"   cts "\t" $0 "\tIgnored" }
    else if (bestlen == 0)
         { print cdate "\t1 Unmatched\t" cts "\t" $0 "\tUnmatched" }
    else { print cdate "\t0 " bestproj "\t" cts "\t" $0 "\t" bestproj }
  }
' "$KEY" "$INPUT" \
| LC_ALL=C sort -t"$TAB" -k1,1 -k2,2 -k3,3 > "$sorted"

# Stage 2: emit grouped output. Read the sorted data twice — first to count
# commits per (day, project) so each header can show that day's count, then to
# print the day/project headers and commit lines.
awk -F"$TAB" '
  FNR == NR {                             # pass 1: per-(day, project) counts
    cnt[substr($4, 1, 10) SUBSEP $5]++
    next
  }
  # pass 2: emit
  FNR == 1 { print "Timelog grouped by day, then project"; print "" }
  {
    line = $4; proj = $5
    date = substr(line, 1, 10)
    if (date != curdate) {
      if (printed) print ""
      print "===== " date " ====="
      print ""
      print proj " (" cnt[date SUBSEP proj] ")"
      curdate = date; curproj = proj; printed = 1
    } else if (proj != curproj) {
      print ""
      print proj " (" cnt[date SUBSEP proj] ")"
      curproj = proj
    }
    print line
  }
' "$sorted" "$sorted" > "$OUTPUT"

days="$(grep -c '^===== ' "$OUTPUT" || true)"
commits="$(grep -c '^[0-9]\{4\}-' "$OUTPUT" || true)"
echo "Wrote $commits commit(s) across $days day(s) to $OUTPUT"
