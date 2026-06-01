#!/bin/bash
#
# timelog-by-project.sh — Chunk a timelog.txt (see commit-timelog.sh) into
# billable projects using a folder→project key file.
#
# Output (default ./timelog-by-project.txt) keeps the exact same commit line
# format as the input, but groups commits by day (newest first), and within
# each day by project (alphabetically). Each project header shows that day's
# commit count and an estimated number of billable work hours:
#
#   ===== 2026-05-30 =====   (est 9.5 work hours)
#
#   Willow Creek App (20 commits): Est 6.75 work hours
#   2026-05-30 13:33  blackthorn-software/crewview-rn  Update i18n count
#   2026-05-30 13:25  blackthorn-software/crewview-rn  fix: PR feedback
#
#   WWC Manager (4 commits): Est 2.75 work hours
#   2026-05-30 12:31  wasatch/wwc-manager  ...
#
# Within each day, repos in no key are grouped under "Unmatched" and repos
# listed as "ignore" in the key under "Ignored" — both sorted last so nothing
# billable slips through unnoticed.
#
# --- Hour estimates ---------------------------------------------------------
# Commits are instants, not durations, so hours are estimated by ALLOCATING the
# day's working span across projects, weighted by each project's share of that
# day's commits. The span is SESSION-BASED to avoid counting idle time: a day's
# (non-ignored) commits are clustered into sessions, where a gap longer than
# SESSION_GAP_MINUTES (default 120) starts a new session. Each session
# contributes its first→last duration plus a LEAD_IN_MINUTES (default 45)
# ramp-up credit for work done before its first commit — so a lone commit is
# worth the lead-in alone, and a quiet afternoon between two bursts is NOT
# billed. Ignored repos are non-billable: no estimate, and they never affect the
# span or the split. Each project's hours are rounded to ROUND_MINUTES, with
# leftover rounding units handed to the projects with the largest fractional
# remainder, so the per-project estimates sum exactly to the day total shown in
# the date header.
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
SESSION_GAP_MINUTES=120              # a gap longer than this starts a new work session
LEAD_IN_MINUTES=45                   # ramp-up time credited before each session's first commit
ROUND_MINUTES=15                     # round each project's estimate to this granularity
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

# Stage 2: emit grouped output. Read the sorted data twice — pass 1 tallies
# per-(day, project) commit counts and each day's commit-time span, then derives
# an estimated billable-hours allocation per (day, project); pass 2 prints the
# day/project headers (with counts + estimates) and the commit lines.
awk -F"$TAB" \
    -v gap="$SESSION_GAP_MINUTES" -v leadin="$LEAD_IN_MINUTES" -v roundmin="$ROUND_MINUTES" '
  function fmt(h,   s) {                   # trim trailing zeros: 9.00->9, 2.50->2.5
    s = sprintf("%.2f", h)
    sub(/\.?0+$/, "", s)
    return s
  }
  # Allocate one day d total span across its (non-ignored) projects, weighted by
  # commit share, rounded to whole units with largest-remainder distribution so
  # the per-project hours sum exactly to the day total. The span is session-
  # based: cluster the day commit times, sum each session first->last duration
  # plus a lead-in credit, so idle gaps between bursts are not billed.
  function allocate(d,   i, j, p, n, key, sstart, prev, span, sessions, units, total, exact, fl, assigned, leftover, bi, bf) {
    delete fl_u; delete frac; delete st
    total = dtot[d]                         # day total billable commits
    dayhours[d] = 0
    if (total <= 0) return
    for (i = 1; i <= total; i++) st[i] = tlist[d SUBSEP i]
    for (i = 2; i <= total; i++) {          # insertion sort commit times ascending
      key = st[i]; j = i - 1
      while (j >= 1 && st[j] > key) { st[j + 1] = st[j]; j-- }
      st[j + 1] = key
    }
    span = 0; sessions = 1; sstart = st[1]; prev = st[1]
    for (i = 2; i <= total; i++) {           # sum session durations, split on gaps
      if (st[i] - prev > gap) { span += prev - sstart; sessions++; sstart = st[i] }
      prev = st[i]
    }
    span += prev - sstart                    # close the final session
    span += sessions * leadin                # ramp-up credit per session
    units = int(span / roundmin + 0.5)       # span in whole rounding units
    dayhours[d] = units * roundmin / 60.0
    if (units <= 0) return
    assigned = 0
    for (i = 1; i <= np[d]; i++) {
      p = pname[d SUBSEP i]
      if (p == "Ignored") continue
      exact = units * cnt[d SUBSEP p] / total
      fl = int(exact)
      fl_u[i] = fl; frac[i] = exact - fl
      assigned += fl
    }
    leftover = units - assigned
    while (leftover-- > 0) {                 # hand spare units to largest remainders
      bi = -1; bf = -1
      for (i = 1; i <= np[d]; i++) {
        p = pname[d SUBSEP i]
        if (p == "Ignored") continue
        if (frac[i] > bf) { bf = frac[i]; bi = i }
      }
      if (bi < 0) break
      fl_u[bi]++; frac[bi] = -1
    }
    for (i = 1; i <= np[d]; i++) {
      p = pname[d SUBSEP i]
      if (p == "Ignored") continue
      hours[d SUBSEP p] = fl_u[i] * roundmin / 60.0
    }
  }

  FNR == NR {                              # pass 1: counts + per-day commit times
    date = substr($4, 1, 10); proj = $5
    cnt[date SUBSEP proj]++
    if (!((date SUBSEP proj) in seenpd)) { # register projects per day, in sorted order
      seenpd[date SUBSEP proj] = 1
      np[date]++
      pname[date SUBSEP np[date]] = proj
    }
    if (proj != "Ignored") {               # ignored repos are non-billable
      dtot[date]++
      tlist[date SUBSEP dtot[date]] = substr($4, 12, 2) * 60 + substr($4, 15, 2)
    }
    if (!seenday[date]) { seenday[date] = 1; days[++nd] = date }
    next
  }

  FNR == 1 {                               # between passes: allocate every day
    for (i = 1; i <= nd; i++) allocate(days[i])
    print "Timelog grouped by day, then project"; print ""
  }

  {
    line = $4; proj = $5
    date = substr(line, 1, 10)
    if (date != curdate) {
      if (printed) print ""
      print "===== " date " =====   (est " fmt(dayhours[date]) " work hours)"
      print ""
      print header(date, proj)
      curdate = date; curproj = proj; printed = 1
    } else if (proj != curproj) {
      print ""
      print header(date, proj)
      curproj = proj
    }
    print line
  }

  function header(d, p,   c, label) {
    c = cnt[d SUBSEP p]
    label = p " (" c (c == 1 ? " commit" : " commits") ")"
    if (p == "Ignored") return label       # non-billable: no estimate
    return label ": Est " fmt(hours[d SUBSEP p]) " work hours"
  }
' "$sorted" "$sorted" > "$OUTPUT"

days="$(grep -c '^===== ' "$OUTPUT" || true)"
commits="$(grep -c '^[0-9]\{4\}-' "$OUTPUT" || true)"
echo "Wrote $commits commit(s) across $days day(s) to $OUTPUT"
