#!/bin/bash
media="${1:-/media/backup}"

if test ! -f "${media}"/BMS_BACKUP_V1; then
  for try in 1 2; do
    for i in c d e f; do
      if mount -o ro,noexec,nodev /dev/sd${i}1 "${media}"; then
	test -f "${media}"/BMS_BACKUP_V1 || exit 1
	exit
      fi
    done
    sleep 5
  done
fi
