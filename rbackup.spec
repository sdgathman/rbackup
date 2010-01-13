Summary: BMS Backup Scripts
Name: rbackup
Version: 0.1
Release: 1.EL5
Source: rbackup-%{version}.tar.gz
#Patch: rbackup.patch
License: GPL
BuildRoot: /var/tmp/rbackup-root
Group: Applications/Console
Requires: rsync

%description
Backup scripts used by BMS.  These make heavy use of rsync --link-dest
and the backup media is a filesystem or directory tagged with a file
named BMS_BACKUP_V1 at the root.  A backup directory has backups for
multiple systems, and each system has multiple dates.  Unchanged files
are hardlinked between backups to save space (this is what --link-dest does).

Backup source can be a remote system, or a local snapshot.  Destination
can be rsync directories, or gzipped tarball with --rsyncable (useful
for copying to remote backup servers).

%prep
%setup -q
#patch -p1 -b .bms
#chmod a+x *.sh	# patched in scripts not executable

%build

%install
test -d "%{buildroot}" && rm -rf "%{buildroot}"

mkdir -p "%{buildroot}"/var/backup

for i in *.sh *.py *.LV *.rmt; do
  case "$i" in
  lvbackup.sh) cp -p $i "%{buildroot}"/var/backup/${i%.sh};;
  *) cp -p $i "%{buildroot}"/var/backup/$i;;
  esac
done

%files 
%defattr(-,bin,bin)
%dir /var/backup
/var/backup/backup.LV
/var/backup/backup.rmt
%config /var/backup/backup.sh
/var/backup/bprune.py
/var/backup/bprune.pyc
/var/backup/bprune.pyo
/var/backup/catalog.sh
/var/backup/ckspace.sh
/var/backup/lvbackup
/var/backup/lvtar.sh
/var/backup/norpm.sh
%config /var/backup/prune.sh
/var/backup/rotate.sh
/var/backup/spaceleft.sh
/var/backup/unmount.sh

%changelog
* Wed Jan 13 2010 Stuart Gathman <stuart@bmsi.com>	0.1-1
- initial package
