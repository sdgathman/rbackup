#!/bin/bash
media="/media/backup"
minfree="20000000"

cd /var/backup
sh mount.sh ${media} || exit 1

/var/backup/ckspace.sh "${media}" "${minfree}" || exit 1

for i in $*; do
  sh backup.LV $i "${media}"
done

s1=`cat "${media}"/begin_free`
s2=`/var/backup/spaceleft "${media}"`
let used="s1-s2"
echo "$used blocks on ${media} used for backup"

# Catalog backups on this media
/var/backup/catalog.sh "${media}"

# Unmount and fsck when done so drive doesn't get bored and doze off.
/var/backup/unmount.sh "${media}"
