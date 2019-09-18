# Rsync Backup

These scripts implement dated backups using rsync with --link-dest to 
efficiently de-dup between backups.

These are production scripts, but NOT NEWBIE FRIENDLY!

In other words, we are just sharing and this is not packaged for those
who haven't been using it for years.  However, people often ask,
"how do I implement an Apple Time Machine™ like backup with rsync"?
The answer is, rsync doesn't do it directly, but it is fairly straighforward
to script, or even do manually.  The key idea is a directory
for each date, and sharing unchanged files between backups with --link-dest.
This internal package is an example of how we did it.  

Do not blindly run any of the scripts without understanding them.  
They run LVM commands that could destroy data.  While there
are a few safeguards to ensure our safety, e.g. checking that the backup
directory was intended to be a backup directory (checks for a Magic Filename),
your system could easily have some setup that we didn't anticipate.  

These script are designed to use LVM to take snapshots of the filesystems
to be backed up.  You need snapshots to get consistent backups - but
you can still get useful backups via rsync without it by running it
repeatedly until no changes are detected.  These scripts do not do that.


