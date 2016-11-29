#!/usr/bin/python

import os,sys,socket,time

if len(sys.argv)<3:
    print "need ret ip or vmname"
    sys.exit(1)

retip=sys.argv[2]
vmname=sys.argv[1]

print "xl cre ../ubuntu-64"
os.system("xl cre ../ubuntu-64/"+vmname)
print "wait for 60sec"
time.sleep(60)

print "echo 0 > /sys/kernel/vgt/control/foreground_vm"
os.system("echo 0 > /sys/kernel/vgt/control/foreground_vm")

port=8081

print "getting ip"
os.system("./ip_list.sh > hosts.txt")
f=open('hosts','r+')
iplist=f.readlines();
f.close()

s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)

li=''
for ip in iplist:
    li=li+ip

s.sendto(li,(retip,port))
print "ip sent"
