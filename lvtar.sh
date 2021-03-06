#!/bin/sh

# Create full backup of LV to local tar file, then rsync to remote host
# lvtar.sh vgname/lvname rmthost rmtuser

bindir="/var/backup"
cd /var/backup
. /etc/sysconfig/rbackup

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
fstype="$(blkid -o value -s TYPE ${snappath})"
case "$fstype" in
xfs) opts="ro,noexec,nodev,nouuid";;
*) opts="ro,noexec,nodev";;
esac
mount -o "$opts" "$snappath" "$tmpdir" 
fi

fname=`date +${h%%.example.com}-%y%b%d.tar.gz`

oname=`ls -tr /backup/${h}-* | head -1`
echo rm -f "$oname"
rm -f "$oname"

cd "$tmpdir"
tar cf - --one-file-system --totals -X /var/backup/${h}.exclude . |
gzip --rsyncable >/opt/"$fname"
sync
#ssh ${host} -l "${h}" "dd bs=20b of=$fname"
cd -
umount "$tmpdir"
/usr/sbin/lvremove  -f "$snappath"

cd /opt
rsync -avy "$fname" "${h}@${host}:$fname" ||
rsync -avy "$fname" "${h}@${host}:$fname" || exit 1
ssh -l ${h} ${host} sh ${bindir}/prune.sh
exit

#rm `readlink last`
#mv -f current last
