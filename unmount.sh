#!/bin/sh

media="${1:-/media/backup}"

label="/sbin/blkid -o value -s LABEL"

test -f "${media}/BMS_BACKUP_V1" || sleep 5
if test -f "${media}/BMS_BACKUP_V1"; then
	set - `df -P "${media}" | tail -1`
	dev="$1"
	fs="$6"
	if [ "${fs}" = "${media}" ]; then
          read fslabel fstype <<< $(echo $(${label} -s TYPE "${dev}"))
	  date +"%F %T ${fslabel}" >>/var/backup/media.log
	  case "$fstype" in
		  "xfs") fsck="/sbin/fsck.xfs";;
		  *) fsck="/sbin/fsck";;
	  esac
	  umount "${dev}" && ${fsck} -p "${dev}"
	else
	  echo "${media} not mounted on ${dev}"
	  umount "${media}"
	fi
else
	#umount "${media}"
  	echo "${media} is not formatted as a backup drive"
	exit 1
fi
