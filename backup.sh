#!/bin/bash
media="/media/backup"
minfree="20000000"

cd /var/backup
if test ! -f "${media}"/BMS_BACKUP_V1; then
        mount "${media}" || exit 1
        test -f "${media}"/BMS_BACKUP_V1 || exit 1
fi

s1=`/var/backup/spaceleft "${media}"`
echo "$s1 blocks free on ${media}"
if [ "$s1" -lt "${minfree}" ]; then
  echo "Insufficient free space on ${media}"
  mount -o remount,rw "${media}"
  sh prune.sh -0 | xargs -0 -t rm -rf
  s1=`/var/backup/spaceleft "${media}"`
  echo "$s1 blocks free on ${media}"
  [ "$s1" -lt "${minfree}" ] && exit 1
fi

for i in $*; do
  sh backup.LV $i "${media}"
done

s2=`spaceleft "${media}"`
let used="s1-s2"
echo "$used blocks on ${media} used for backup"
