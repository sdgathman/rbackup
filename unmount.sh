#!/bin/sh

media="${1:-/media/backup}"

test -f "${media}/BMS_BACKUP_V1" || sleep 5
test -f "${media}/BMS_BACKUP_V1" || exit

set - `df -P "${media}" | tail -1`
dev="$1"
fs="$6"
if [ "${fs}" = "${media}" ]; then
  umount "${media}" && e2fsck -p "${dev}"
else
  echo "${media} not mounted on ${dev}"
  umount "${media}"
fi
