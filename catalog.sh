#!/bin/sh
media="${1:-/media/backup}"

test -f "${media}/BMS_BACKUP_V1" || sleep 5
if test -f "${media}/BMS_BACKUP_V1"; then
	set - `df -P "${media}" | tail -1`
	dev="$1"
	fs="$6"
	if [ "${fs}" = "${media}" ]; then
		label="$(/sbin/e2label "${dev}")"
		ls -d "${media}"/*/[0-9]?????? |
		while read ln; do
		  echo $label ${ln#$media/}
		done > catalog.new
		grep -v "^${label} " catalog.txt |
		sort -u -o catalog.txt catalog.new -
	fi
fi
