#!/bin/sh

. /etc/sysconfig/rbackup
media="${1:-$media}"; shift
bindir=/usr/libexec/rbackup

cd /var/backup
# list backup directories to remove to make room on ${media}
# customize to give priority, keep minimum backups, etc
for dir in "${media}"/*; do
  if test -h "$dir"/last && test -d "$dir"/last; then
    ${bindir}/bprune.py "$@" "$dir"/[0-3][0-9]*
  fi
done
