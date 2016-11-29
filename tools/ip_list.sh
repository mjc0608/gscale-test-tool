#!/bin/bash
# using staf extend to xl list
declare -a NAME_LST
declare -a ID_LST
declare -a MEM_LST
declare -a CPU_LST
# extend info mation
declare -a MAC_LST
declare -a IP_LST
declare -a STAF_LST
declare -a ALIAS_LST
declare -a OS_LST

BRADGE=xenbr0

[[ ! -f /var/run/xenstored.pid ]] && echo "Miss xen service" && exit 1
# 1. catch from xl list
for i in `xl list|sed '1d'|awk '{print $2;}'`;
do
    [[ "$1" ]] && [[ "$1" = "$i" ]] && VM_ID=$1 && shift $#
    idx=${#ID_LST[*]}
    ID_LST[$idx]="$i"
done
for i in `xl list|sed '1d'|awk '{print $1;}'`;
do
    idx=${#NAME_LST[*]}
    NAME_LST[$idx]="$i"
done
for i in `xl list|sed '1d'|awk '{print $3;}'`;
do
    idx=${#MEM_LST[*]}
    MEM_LST[$idx]="$i"
done
for i in `xl list|sed '1d'|awk '{print $4;}'`;
do
    idx=${#CPU_LST[*]}
    CPU_LST[$idx]="$i"
done

# 2. catch mac
MAC_LST[0]=`ifconfig -v $BRADGE|grep $BRADGE|awk '{print $NF;}'|tr [:lower:] [:upper:]`
for i in ${ID_LST[*]};
do
    idx=${#MAC_LST[*]}
    [[ $i -eq 0 ]] && continue 
    MAC_LST[$idx]=`/usr/bin/xenstore-read /local/domain/0/backend/vif/$i/0/mac 2>/dev/null|tr [:lower:] [:upper:]`
done

# 3. catch ip
IP_LST[0]=`ip route show|grep "$BRADGE"|sed '1d'|awk '{print $NF}'`
fetch_ip=`ip route show|grep "$BRADGE"|sed '1d'|awk '{print $1}'`
ip_result=`nmap -sn -n $fetch_ip`
for i in ${ID_LST[*]};
do
    idx=${#IP_LST[*]}
    [[ $i -eq 0 ]] && continue
    [[ ! "${MAC_LST[$idx]}" ]] && MAC_LST[$idx]="Load_Failed" && IP_LST[$idx]="" && continue
    IP_LST[$idx]=`echo $ip_result|sed 's/Nmap/\nNmap/g'|grep "${MAC_LST[$idx]}"|sed -n 's/.*[^0-9]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p'`
done

# 4. check STAF
# STAF status:
# u: unsupport
# a: active
# n: not run
# m: miss ip
which staf 2>&1 > /dev/null
local_staf=$?
[[ $local_staf -ne 0 ]] && [[ -f /usr/local/staf/STAFEnv.sh ]] && source /usr/local/staf/STAFEnv.sh && local_staf=0
if [ $local_staf -ne 0 ];then
    echo "dom0 miss staf some extend information maybe incorrect"
    for i in ${ID_LST[*]};
    do
        idx=${#STAF_LST[*]}
        STAF_LST[$idx]="u"
    done
else
    # check STAF support
    for i in ${ID_LST[*]};
    do
        idx=${#STAF_LST[*]}
        if [ "${IP_LST[$idx]}" ];then
            staf ${IP_LST[$idx]} ping ping 2>&1 >/dev/null
            [[ $? -eq 0 ]] && STAF_LST[$idx]="a"
            [[ ! "${STAF_LST[$idx]}" ]] && STAF_LST[$idx]="n"
        else
            STAF_LST[$idx]="m"
        fi
    done
fi

# 5. check OS
TMP_SYSTEMINFO="/tmp/staf_systeminfo.$RANDOM"
rm -rf $TMP_SYSTEMINFO
OS_LST[0]=`cat /etc/issue.net`" "`uname -rp`
for i in ${ID_LST[*]};
do
    idx=${#OS_LST[*]}
    [[ $i -eq 0 ]] && continue
    # OS image
    if [ "${STAF_LST[$idx]}" != "a" ];then
        xdisk_path=`/usr/bin/xenstore-list /local/domain/0/backend/qdisk/$i 2>/dev/null`
        OS_LST[$idx]=`/usr/bin/xenstore-read /local/domain/0/backend/qdisk/$i/$xdisk_path/params 2>/dev/null|awk -F ':' '{print $2;}'`
        [[ ! "${OS_LST[$idx]}" ]] && OS_LST[$idx]="unknow"
        continue
    fi
    # ask windows using systeminfo dump information
    staf ${IP_LST[$idx]} process start command systeminfo wait returnstdout returnstderr 2>&1 > $TMP_SYSTEMINFO
    if [ $? -eq 10 ];then
        # linux side use "/etc/issue.net & uname -rp"
        staf ${IP_LST[$idx]} process start command cat parms /etc/issue.net wait returnstdout 2>&1 > $TMP_SYSTEMINFO
        sed -i 's/Data/OS Name/g' $TMP_SYSTEMINFO
        staf ${IP_LST[$idx]} process start command uname parms -rp wait returnstdout 2>&1 >> $TMP_SYSTEMINFO
        sed -i 's/Data/System Type/g' $TMP_SYSTEMINFO
    fi
    dos2unix $TMP_SYSTEMINFO 2>/dev/null && sed -i 's/[[:blank:]]*$//g' $TMP_SYSTEMINFO
    OS_LST[$idx]=`cat $TMP_SYSTEMINFO|grep "OS Name"|awk -F ':' '{print $2;}'|sed 's/^[[:blank:]]*//g'`
    [[ ! "${OS_LST[$idx]}" ]] && OS_LST[$idx]="unknow" && continue
    OS_LST[$idx]=${OS_LST[$idx]}" "`cat $TMP_SYSTEMINFO|grep "System Type"|awk -F ':' '{print $2;}'|sed 's/^[[:blank:]]*//g'`
    rm -rf $TMP_SYSTEMINFO
done

# 6. convert OS to alias Name
for((idx=0;idx<${#OS_LST[*]};idx++));
do
    # unknow OS
    [[ `echo ${OS_LST[$idx]}|grep "unknow"` ]] && ALIAS_LST[$idx]=${OS_LST[$idx]} && continue
    # OS is file
    [[ -f "${OS_LST[$idx]}" ]] && ALIAS_LST[$idx]="file" && continue
    # catch Windows
    [[ `echo ${OS_LST[$idx]}|grep "Windows"` ]] && ALIAS_LST[$idx]="win"`echo ${OS_LST[$idx]}|awk '{print $3;}'`
    # spec reset for windos server
    [[ `echo ${OS_LST[$idx]}|grep "Windows"|grep "Server"` ]] && ALIAS_LST[$idx]="win"`echo ${OS_LST[$idx]}|awk '{print $4;}'`
    # catch Linux
    [[ `echo ${OS_LST[$idx]}|grep -v "Windows"` ]] && ALIAS_LST[$idx]=`echo ${OS_LST[$idx]}|awk '{print $1;}'|tr [:upper:] [:lower:]`
    # Processor
    ALIAS_LST[$idx]=${ALIAS_LST[$idx]}"-"
    [[ `echo ${OS_LST[$idx]}|grep "[Xx]64"` ]] && ALIAS_LST[$idx]=${ALIAS_LST[$idx]}"64" 
    [[ `echo ${OS_LST[$idx]}|grep "[Xx]86_64"` ]] && ALIAS_LST[$idx]=${ALIAS_LST[$idx]}"64"
    [[ `echo ${OS_LST[$idx]}|grep -v "[Xx]86_64" |grep -v "[Xx]64"` ]] && ALIAS_LST[$idx]=${ALIAS_LST[$idx]}"32"
done

# 7. display all VM
for((idx=0;idx<${#ID_LST[*]};idx++));
do
    [[ ! "${IP_LST[$idx]}" ]] && IP_LST[$idx]="Miss_IP"
    [[ ${#IP_LST[$idx]} -lt 8 ]] && echo -ne "${IP_LST[$idx]}\t\t"
    [[ ${#IP_LST[$idx]} -ge 8 && ${#IP_LST[$idx]} -lt 16 ]] && echo -ne "${IP_LST[$idx]}\t"
    echo
#    echo -e "${OS_LST[$idx]}"
done
