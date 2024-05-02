#!/bin/sh
media="${1:-/media/backup}"
bindir="/usr/libexec/rbackup"

test -f "${media}/BMS_BACKUP_V1" || sleep 5
if test -f "${media}/BMS_BACKUP_V1"; then
	set - `df -P "${media}" | tail -1`
	dev="$1"
	fs="$6"
	if [ "${fs}" = "${media}" ]; then
	    if test -x "${bindir}/scan.py"; then
	        python3 "${bindir}/scan.py" "${media}" > catalog.csv
	    else
		label="$(/sbin/blkid -o value -s LABEL "${dev}")"
		if ls -d "${media}"/*/[0-9]?????? |
		while read ln; do
		  echo $label ${ln#$media/}
		done > catalog.new; then
		test -f catalog.txt || touch catalog.txt
		grep -v "^${label} " catalog.txt |
		sort -u -o catalog.txt catalog.new -
		fi
	    fi
	fi
fi
