#!/usr/bin/python

import os,sys,socket

host_file="./hosts"
f=open(host_file,'r+')
iplist=f.readlines()
f.close()

if (not os.path.exists("/home/mochi/img/test-tools/log/gt1/"+str(len(iplist)))):
    os.mkdir("/home/mochi/img/test-tools/log/gt1/"+str(len(iplist)))
for ip in iplist:
    while (ip[-1]=='\n' or ip[-1]=='\t'):
        ip=ip[:-1]
    
    print ("staf_get.sh "+ip+" C://perf/log_XGT-WIN7-32.html  /home/mochi/img/test-tools/tmp")
    os.system("staf_get.sh "+ip+" C://perf/log_XGT-WIN7-32.html  /home/mochi/img/test-tools/tmp")

    os.system("mv /home/mochi/img/test-tools/tmp/log_XGT-WIN7-32.html  /home/mochi/img/test-tools/log/gt1/"+str(len(iplist))+'/'+ip+'.html')
