#!/bin/bash

. /etc/sysconfig/rbackup
media="${1:-$media}"

if test ! -f "${media}"/BMS_BACKUP_V1; then
  for try in 1 2; do
    for i in $devices; do
      if mount -o ro,noexec,nodev "/dev/$i" "${media}"; then
	test -f "${media}"/BMS_BACKUP_V1 || exit 1
	exit
      fi
    done
    sleep 5
  done
fi
