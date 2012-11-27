#!/bin/sh

media="${1:-/media/backup}"

if test -x /sbin/e4label; then
  label="/sbin/e4label"
else
  label="/sbin/e2label"
fi

test -f "${media}/BMS_BACKUP_V1" || sleep 5
if test -f "${media}/BMS_BACKUP_V1"; then
	set - `df -P "${media}" | tail -1`
	dev="$1"
	fs="$6"
	if [ "${fs}" = "${media}" ]; then
	  date +"%F %T $("$label" "${dev}")" >>/var/backup/media.log
	  umount "${dev}" && /sbin/fsck -p "${dev}"
	else
	  echo "${media} not mounted on ${dev}"
	  umount "${media}"
	fi
else
	#umount "${media}"
  	echo "${media} is not formatted as a backup drive"
	exit 1
fi
