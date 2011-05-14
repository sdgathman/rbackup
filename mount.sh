#!/bin/bash
media="${1:-/media/backup}"

if test ! -f "${media}"/BMS_BACKUP_V1; then
  if mount "${media}" || mount -o ro,noexec,nodev /dev/sdd1 "${media}"; then
    test -f "${media}"/BMS_BACKUP_V1 || exit 1
  else
    sleep 5
    mount "${media}" || mount -o ro,noexec,nodev /dev/sdd1 "${media}" || exit 1
    test -f "${media}"/BMS_BACKUP_V1 || exit 1
  fi
fi
