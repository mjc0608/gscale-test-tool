#!/usr/bin/python

import os,sys,socket

host_file="./hosts"
f=open(host_file,'r+')
iplist=f.readlines()
f.close()

if (not os.path.exists("/home/mochi/img/test-tools/log/gt2/"+str(len(iplist)))):
    os.mkdir("/home/mochi/img/test-tools/log/gt2/"+str(len(iplist)))
for ip in iplist:
    while (ip[-1]=='\n' or ip[-1]=='\t'):
        ip=ip[:-1]
    
    os.system("rm *.enc *.xml Handle.txt")    
    print ("staf_get.sh "+ip+" C://perf/3dmark06.3dr /home/mochi/img/test-tools/tmp")
    os.system("staf_get.sh "+ip+" C://perf/3dmark06.3dr /home/mochi/img/test-tools/tmp")
    print ("unzip /home/mochi/img/test-tools/tmp/3dmark06.3dr")
    os.system("unzip /home/mochi/img/test-tools/tmp/3dmark06.3dr")

    os.system("xml2 < /home/mochi/img/test-tools/Result.xml > /home/mochi/img/test-tools/log/gt2/"+str(len(iplist))+'/'+ip+'.log')
