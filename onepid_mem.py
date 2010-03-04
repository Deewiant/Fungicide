#!/usr/bin/env python
import sys, os, select, string, time

if len(sys.argv) != 2:
	sys.stderr.write("One arg plz: file name\n");
	sys.exit(1)

if os.geteuid() != 0:
	sys.stderr.write("Sorry, root permission required.\n");
	sys.exit(1)

def getMemStats(pid):
	Private=0
	Shared=0
	for line in open("/proc/"+str(pid)+"/smaps").readlines(): #open
		if line.startswith("Shared"):
			Shared+=int(line.split()[1])
		elif line.startswith("Private"):
			Private+=int(line.split()[1])
	return (Private, Shared)

fd = os.open(sys.argv[1], os.O_RDONLY)
f = os.fdopen(fd)
while True:
	#select.select([fd], [], [])
	pid = string.strip(f.readline())

	if pid == '':
		time.sleep(0.001)
		continue

	if pid == 'd':
		print '--'
		continue

	if pid == 'q':
		break

	total=0
	pid=int(pid)
	try:
		private, shared = getMemStats(pid)
		print shared + private
	except:
		continue #process gone
