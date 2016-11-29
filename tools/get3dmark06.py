#!/usr/bin/python

import os,sys,socket

host_file="./hosts"
f=open(host_file,'r+')
iplist=f.readlines()
f.close()

if (not os.path.exists("/home/mochi/img/test-tools/log/3dmark06/"+str(len(iplist)))):
    os.mkdir("/home/mochi/img/test-tools/log/3dmark06/"+str(len(iplist)))
for ip in iplist:
    while (ip[-1]=='\n' or ip[-1]=='\t'):
        ip=ip[:-1]
    
    os.system("rm *.enc *.xml Handle.txt")    
    print ("staf_get.sh "+ip+" C://perf/3dmark06.3dr /home/mochi/img/test-tools/tmp")
    os.system("staf_get.sh "+ip+" C://perf/3dmark06.3dr /home/mochi/img/test-tools/tmp")
    print ("unzip /home/mochi/img/test-tools/tmp/3dmark06.3dr")
    os.system("unzip /home/mochi/img/test-tools/tmp/3dmark06.3dr")
    print ("xml2 < /home/mochi/img/test-tools/Result.xml |sed '/Setting/d;/@/d;/Status/d;/Category/d;/Plain/d;1d'|awk -F '=' '{print $2;}'|sed '/^$/d;/Score/,+1!d;/Game Score/,+1d;s:$:,:g'|grep -v 'Score'|grep -v '\-1'|sed 's/,//g' > "+"/home/mochi/img/test-tools/log/3dmark06/"+str(len(iplist))+"/"+ip+".log")
    os.system("xml2 < /home/mochi/img/test-tools/Result.xml |sed '/Setting/d;/@/d;/Status/d;/Category/d;/Plain/d;1d'|awk -F '=' '{print $2;}'|sed '/^$/d;/Score/,+1!d;/Game Score/,+1d;s:$:,:g'|grep -v 'Score'|grep -v '\-1'|sed 's/,//g' > "+"/home/mochi/img/test-tools/log/3dmark06/"+str(len(iplist))+"/"+ip+".log")
