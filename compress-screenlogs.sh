#!/bin/bash
#
# Compress finished screen logs. Gzips every *.log in the screenlog dir that a
# live screen window isn't still writing to, so it's safe to run from cron: an
# active log is skipped (its window still holds the file open) and picked up on
# a later run once the window closes.
#
# It also prunes compressed logs older than RETENTION_DAYS to bound growth.
#
# Usage: compress-screenlogs.sh [logdir]   (default: ~/.screenlogs)

LOGDIR="${1:-$HOME/.screenlogs}"

# Delete *.log.gz older than this many days (set to 0 to keep forever).
RETENTION_DAYS="${RETENTION_DAYS:-365}"

[ -d "$LOGDIR" ] || exit 0

# -mmin +5 skips logs touched in the last few minutes as an extra guard against
# racing a just-active window; the lsof check is the real safety net.
find "$LOGDIR" -maxdepth 1 -type f -name '*.log' -mmin +5 -print0 |
while IFS= read -r -d '' f; do
	# Skip logs a running screen window still has open.
	if lsof -- "$f" >/dev/null 2>&1; then
		continue
	fi

	out="$f.gz"
	if [ -e "$out" ]; then
		# A .gz with this exact name already exists (screen reused the
		# filename on a later session). Disambiguate with the log's mtime
		# so neither the old archive nor this one is lost.
		out="${f%.log}.$(date -r "$f" +%Y%m%d-%H%M%S).log.gz"
	fi
	# Compress to a new file and only remove the original on success, so an
	# interrupted run never loses data.
	if gzip -c -- "$f" > "$out"; then
		rm -- "$f"
	else
		rm -f -- "$out"
	fi
done

# Prune old archives. Scoped tightly: only *.log.gz directly in LOGDIR.
if [ "${RETENTION_DAYS}" -gt 0 ]; then
	find "$LOGDIR" -maxdepth 1 -type f -name '*.log.gz' -mtime +"${RETENTION_DAYS}" -delete
fi
