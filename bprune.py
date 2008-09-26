#!/usr/bin/python

import time
import os

SECS_IN_DAY = 24*60*60

def variance(s):
  n = len(s)
  avg = sum(s)/n
  avg2 = sum(x*x for x in s)/n
  return avg2/(avg*avg)

# The first part of the score is the number of times backup intervals
# decrease with age.  Reducing that to zero is the first priority.
# The second part of the score is the variance of changes in backup intervals.
# Minimizing this makes for intervals that increase smoothly with age.

def score(dts,years=1,now=None,debug=False):
  "return two part badness score"
  #last = dts[0][0] - 60 * SECS_IN_DAY
  if not now:
    now = time.time()
  last = now - years * 365.25 * SECS_IN_DAY
  d0 = [x[0] for x in dts]
  d0.insert(0,last)
  d0.append(now)
  cnt = 0
  n = len(dts)
  d1 = []
  d2 = []
  if n < 2: return 0
  for i,(t,path) in enumerate(dts):
    delta = (t - last)/SECS_IN_DAY
    d1.append(delta)
    if i:
      delta2 = last_delta - delta;
      d2.append(delta2)
      if delta2 < 0:
        cnt += 1
    last_delta = delta
    last = t
  delta = (now - last)/SECS_IN_DAY
  d1.append(delta)
  delta2 = last_delta - delta
  d2.append(delta2)
  if delta2 < 0:
    cnt += 1
  score = variance(d2[1:])
  if debug:
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
    newlist = list(pathlist)
    del newlist[i]
    cnt = score(newlist,years,now)
    # prune oldest backup only when past retention interval
    if (i or t < last) and (not best or cnt <= best[1]):
      best = i,cnt
  return best

# Given a list of backup dates, output which should be deleted 
# so as to preserve archive requirements:
#  1) maximum time span
#  2) decreasing density with age
#  3) retention time - amount of time a given backup must be available
#  4) retention cycles - number of backups that must be available

def prune(pathlist,n=0,years=1,now=time.time(),debug=False):
  mktime = time.mktime
  strptime = time.strptime
  dts = [ (mktime(strptime(os.path.basename(path),'%y%b%d')),path)
    for path in pathlist]
  dts.sort()
  i,cnt = improve(dts,years,now)
  rc = dts[i][1]
  while n > 0:
    print dts[i][1]
    del dts[i]
    if debug:
      score(dts,years,now,True)
    n -= 1
    if not n: break
    i,cnt = improve(dts,years,now)
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
      nm = prune(l,debug,years,t,debug=debug)
      l.remove(nm)
      print nm,'|',l
    else:
      print l

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
  parser.add_option("-r", "--remove", dest="count", default=1, type="int",
                help="Number of names to select for removal")
  parser.add_option("-k", "--keep", dest="keep", default=None, type="int",
                help="Number of names to keep")
  parser.add_option("-m", "--maxage", dest="maxage", default=24, type="int",
                help="backup retension period in months")
  parser.add_option("-t", "--test", dest="test", default=0, type="int",
                help="number of test cycles to run")

  (opt, args) = parser.parse_args()
  if opt.keep and opt.test:
    testCycle(opt.keep,opt.test,opt.maxage/12.0,opt.verbose)
  if args:
    if opt.keep:
      opt.count = len(args) - opt.keep
    if opt.count <= 0:
      import sys
      sys.exit(1)
    prune(args,n=opt.count,years=opt.maxage/12.0,debug=opt.verbose)
  elif not opt.test:
    parser.print_help()
