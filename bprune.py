#!/usr/bin/python

import time
import os
import re
import sys
import errno

SECS_IN_DAY = 24*60*60

def variance(s):
  """Return standard variance of a numeric series.
  Example:
  >>> '%.2f'%variance([1,2,3,4,5,6])
  '2.92'
  """
  n = float(len(s))
  avg = sum(s)
  avg2 = sum([x*x for x in s])
  return (avg2 - avg*avg/n)/n

# The first part of the score is the number of times backup intervals
# decrease with age.  Reducing that to zero is the first priority.
# The second part of the score is the variance of changes in backup intervals.
# Minimizing this makes for intervals that increase smoothly with age.

def score(d0,years=1,now=None,debug=False):
  """Return two part badness score from list of timestamps.
  Example:
  >>> '(%d, %.1f)'%score([extract_date(s) \
        for s in '08Apr03','08Jun04','08Sep13','08Nov04','08Nov11'], \
        now=extract_date('08Nov17'))
  '(1, 4988.6)'
  """
  if not now:
    now = time.time()
  last = now - years * 365.25 * SECS_IN_DAY
  cnt = 0
  if len(d0) < 2: return 0,0
  d1 = []
  d2 = []
  for i,t in enumerate(d0):
    delta = (t - last)/SECS_IN_DAY
    d1.append(delta)
    if i:
      delta2 = last_delta - delta;
      d2.append(delta2)
      if delta2 < 0:
        cnt += 1
    last_delta = delta
    last = t
  score = variance([x*y for x,y in enumerate(d2)])
  if debug:
    d0.insert(0,last)
    print [time.strftime('%y%b%d',time.localtime(t)) for t in d0]
    print d1
    print d2
    print cnt,score
  return cnt,score

def improve(pathlist,years,now):
  "return idx and resulting score if pruned of the optimal backup to prune"
  best = None
  last = now - years * 365.25 * SECS_IN_DAY
  # never prune last backup
  for i,(t,path) in enumerate(pathlist[:-1]):
    # try deleting each backup to see which produces best score
    newlist = [t for t,p in pathlist]
    del newlist[i]
    #newlist.append(now)
    cnt = score(newlist,years,now)
    # prune oldest backup only when past retention interval
    if (i or t < last) and (not best or cnt < best[1]):
      best = i,cnt
  return best

RE_DATE = re.compile(r'\d\d[A-Za-z]{3}\d\d')
def extract_date(path):
  "Extract date from filename or string."
  s = os.path.basename(path)
  m = RE_DATE.search(s)
  if m:
    s = m.group()
    t = time.mktime(time.strptime(s,'%y%b%d'))
  else:
    t = os.path.getmtime(path)
  #print t,path
  return t

# Given a list of backup dates, output which should be deleted 
# so as to preserve archive requirements:
#  1) maximum time span
#  2) decreasing density with age
#  3) retention time - amount of time a given backup must be available
#  4) retention cycles - number of backups that must be available

def prune(pathlist,n=0,years=1,now=time.time(),debug=False):
  try:
    dts = [ (extract_date(path),path) for path in pathlist]
  except OSError,x:
    if x.errno != errno.ENOENT: raise
    print >>sys.stderr,'%s: %s'%(x.filename,x.strerror)
    return []
  dts.sort()
  rc = []
  try:
    i,cnt = improve(dts,years,now)
    while n > 0:
      rc.append(dts[i][1])
      del dts[i]
      if debug:
        score(dts,years,now,True)
      n -= 1
      if not n: break
      i,cnt = improve(dts,years,now)
  except TypeError: pass
  return rc

def testCycle(n,cnt,years=1,debug=False):
  t = time.time() - cnt * SECS_IN_DAY
  l = []
  while cnt > 0:
    t += SECS_IN_DAY
    name = time.strftime('%y%b%d',time.localtime(t))
    l.append(name)
    cnt -= 1
    if len(l) > n:
      a = prune(l,len(l) - n,years,t,debug=debug)
      for nm in a:
        l.remove(nm)
        print nm,'|',l
    else:
      print l

def _test():
  import doctest, bprune 
  return doctest.testmod(bprune)

if __name__ == '__main__':
  from optparse import OptionParser
  USAGE="""Usage: %prog [-v] [-c cnt] [-m months] file ...

Example:
  bprune /media/backup/C4/[0-9]*        # print backup cycle to remove
  """

  parser = OptionParser(prog="bprune",usage=USAGE)
  parser.add_option("-v", "--verbose", dest="verbose",
                default=False, action="store_true",
                help="show 1st and 2nd order backup intervals and score")
  parser.add_option("-0", "--print0", dest="print0", default=False,
		action="store_true", help="output null terminated paths")
  parser.add_option("-r", "--remove", dest="count", default=1, type="int",
                help="Number of names to select for removal")
  parser.add_option("-k", "--keep", dest="keep", default=None, type="int",
                help="Number of names to keep")
  parser.add_option("-m", "--maxage", dest="maxage", default=24, type="int",
                help="backup retention period in months")
  parser.add_option("-t", "--test", dest="test", default=0, type="int",
                help="number of test cycles to run")

  (opt, args) = parser.parse_args()
  if opt.keep and opt.test:
    testCycle(opt.keep,opt.test,opt.maxage/12.0,opt.verbose)
  if args:
    if opt.keep:
      opt.count = len(args) - opt.keep
    if opt.count <= 0:
      sys.exit(1)
    for nm in prune(args,n=opt.count,years=opt.maxage/12.0,debug=opt.verbose):
      if opt.print0:
        sys.stdout.write(nm+'\0')
      else:
        print nm
  elif not opt.test:
    parser.print_help()
    _test()
