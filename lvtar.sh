#!/bin/sh
cd /var/backup

if test "$#" -lt 2; then
  echo "Usage: $0 SRCLV DESTDIR"
  exit 2
fi
lvpath="$1"
host="$2"
h="${3:-bms}"
shift 2

set -x
lvname="${lvpath##*/}"
lvname="${lvname##*-}"
snapname="${lvname}_SNAP"
snappath="${lvpath}_SNAP"
tmpdir="/mnt/${snapname}"

if true; then
mkdir "${tmpdir}"
# create snapshot of LV
/usr/sbin/lvcreate -s -L 2G -n "$snapname" "$lvpath" || exit 1
set -e
mount -r "$snappath" "$tmpdir" 
fi

fname=`date +${h%%.jsconnor.com}-%y%b%d.tar.gz`

oname=`ls -tr /backup/${h}-* | head -1`
echo rm -f "$oname"
rm -f "$oname"

cd "$tmpdir"
tar cf - -l --totals -X /var/backup/bms.exclude . |
gzip --rsyncable >/opt/"$fname"
sync
#ssh ${host} -l bms "dd bs=20b of=$fname"
cd -
umount "$tmpdir"
/usr/sbin/lvremove  -f "$snappath"

cd /opt
rsync -avy "$fname" "bms@${host}:$fname" ||
rsync -avy "$fname" "bms@${host}:$fname" || exit 1
ssh -l bms ${host} sh prune.sh
exit

#rm `readlink last`
#mv -f current last
