#!/bin/sh

media="${1:-/work6}"
minfree="${2:-5200000}"

if test -e "${media}/BMS_BACKUP_V1"; then
  :
else
  echo "${media} is not formatted as a backup drive"
  exit 1
fi
cd /var/backup
s1=`./spaceleft "${media}"`
echo "$s1 blocks free on ${media}"
if [ "$s1" -lt "${minfree}" ]; then
  echo "Insufficient free space on ${media}, ${minfree} needed."
  mount -o remount,rw "${media}"
  sh prune.sh "${media}" -0 | xargs -0 -t rm -rf
  s1=`./spaceleft "${media}"`
  echo "$s1" >"${media}/begin_free"
  echo "$s1 blocks free on ${media}"
  test "$s1" -ge "${minfree}"
else
  mount -o remount,rw "${media}"
  echo "$s1" >"${media}/begin_free"
  exit 0
fi
