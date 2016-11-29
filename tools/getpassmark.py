#!/usr/bin/python

import os,sys,socket

host_file="./hosts"
f=open(host_file,'r+')
iplist=f.readlines()
f.close()

if (not os.path.exists("/home/mochi/img/test-tools/log/passmark/"+str(len(iplist)))):
    os.mkdir("/home/mochi/img/test-tools/log/passmark/"+str(len(iplist)))
for ip in iplist:
    while (ip[-1]=='\n' or ip[-1]=='\t'):
        ip=ip[:-1]
    
    print ("staf_get.sh "+ip+" C://perf/passmark.log  /home/mochi/img/test-tools/tmp")
    os.system("staf_get.sh "+ip+" C://perf/passmark.log  /home/mochi/img/test-tools/tmp")

    os.system("mv /home/mochi/img/test-tools/tmp/passmark.log  /home/mochi/img/test-tools/log/passmark/"+str(len(iplist))+'/'+ip+'.log')
