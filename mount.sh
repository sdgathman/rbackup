#!/bin/bash
media="${1:-/media/backup}"

if test ! -f "${media}"/BMS_BACKUP_V1; then
  for try in 1 2; do
    for i in sdc1 sdd1 sde1 sdf1; do
      if mount -o ro,noexec,nodev "/dev/$i" "${media}"; then
	test -f "${media}"/BMS_BACKUP_V1 || exit 1
	exit
      fi
    done
    sleep 5
  done
fi
