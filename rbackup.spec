%global __python %{__python3}

Summary: BMS Backup Scripts
Name: rbackup
Version: 0.7
Release: 1%{dist}
Source: rbackup-%{version}.tar.gz
License: GPL
BuildRoot: /var/tmp/rbackup-root
Group: Applications/Console
Requires: rsync python3
BuildArch: noarch

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
sed -i -e '/^bindir=/ s,=.*$,=/usr/libexec/rbackup,' *.sh *.LV *.rmt

%build

%install
test -d "%{buildroot}" && rm -rf "%{buildroot}"

mkdir -p "%{buildroot}/var/backup"
mkdir -p "%{buildroot}%{_libexecdir}/%{name}"
mkdir -p "%{buildroot}%{_sysconfdir}/sysconfig"
mkdir -p "%{buildroot}%{_sharedstatedir}/%{name}"

for i in *.sh *.py *.LV *.rmt; do
  case "$i" in
  lvbackup.sh) cp -p $i "%{buildroot}%{_libexecdir}/rbackup/${i%.sh}";;
  spaceleft.sh) cp -p $i "%{buildroot}%{_libexecdir}/rbackup/${i%.sh}";;
  luks*.sh) cp -p $i "%{buildroot}%{_libexecdir}/rbackup/${i%.sh}";;
  backup.sh) cp -p $i "%{buildroot}/var/backup/$i";;
  prune.sh) cp -p $i "%{buildroot}/var/backup/$i";;
  *) cp -p $i "%{buildroot}%{_libexecdir}/rbackup/$i";;
  esac
done
cp -p rbackup.conf "%{buildroot}%{_sysconfdir}/sysconfig/rbackup"

%files 
%license LICENSE
%defattr(-,bin,bin)
%dir /var/backup
%{_libexecdir}/rbackup
%config(noreplace) /var/backup/backup.sh
%config(noreplace) /var/backup/prune.sh
%config(noreplace) %{_sysconfdir}/sysconfig/*

%changelog
* Sat Mar 28 2020 Stuart Gathman <stuart@gathman.org>	0.6-1
- Don't use nouuid for backup media
- Support backing up XFS volumes
- Fix name of /etc/sysconfig/rbackup

* Sat Mar 28 2020 Stuart Gathman <stuart@gathman.org>	0.5-1
- support XFS backup media
- Put config in /etc/sysconfig/rbackup

* Thu Mar 26 2020 Stuart Gathman <stuart@gathman.org>	0.4-1
- move scripts to /usr/libexec/rbackup

* Wed Dec 12 2012 Stuart Gathman <stuart@gathman.org>	0.3-1
- copy sparse files efficiently, add --delete for continuing interrupted backup

* Tue Aug 16 2011 Stuart Gathman <stuart@bmsi.com>	0.2-1
- mount.sh script to search list of drives for media

* Wed Jan 13 2010 Stuart Gathman <stuart@bmsi.com>	0.1-2
- remove .sh from spaceleft

* Wed Jan 13 2010 Stuart Gathman <stuart@bmsi.com>	0.1-1
- initial package
