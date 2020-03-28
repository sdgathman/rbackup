#!/bin/bash

. /etc/sysconfig/rbackup

media="${media:-/media/backup}"
minfree="20000000"
bindir="/var/backup"
vg="${vg:-rootvg}"

die() {
  echo "$1" >&2
  exit 1
}

cd /var/backup
sh ${bindir}/mount.sh ${media} || exit 1

${bindir}/ckspace.sh "${media}" "${minfree}" || exit 1

for i in $*; do
  case "$i" in
  root) mount -o remount,rw "${media}"
      grep '^/boot$' "$i.exclude" 2>/dev/null || die "Must exclude /boot"
      mkdir -p ${media}/$i/current
      rsync -ravHx --delete --link-dest=${media}/$i/last /boot ${media}/$i/current
      ;;
  esac
  ${bindir}/backup.LV "$i" "${media}" "${vg}"
done

s1=`cat "${media}"/begin_free`
s2=`${bindir}/spaceleft "${media}"`
let used="s1-s2"
echo "$used blocks on ${media} used for backup"

# Catalog backups on this media
${bindir}/catalog.sh "${media}"

# Unmount and fsck when done so drive doesn't get bored and doze off.
${bindir}/unmount.sh "${media}"
