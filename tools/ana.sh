#!/bin/bash

# program list
APP_LST="3dmark06"
#APP_LST="$APP_LST heaven"
#APP_LST="$APP_LST 3dmark11"
#APP_LST="$APP_LST tropics"
#APP_LST="$APP_LST passmark"
# log list
RESULT_LST="3dmark06.3dr"
#RESULT_LST="$RESULT_LST heaven.log"
#RESULT_LST="$RESULT_LST passmark.log"
#RESULT_LST="$RESULT_LST 3dmark11.3dr"
#RESULT_LST="$RESULT_LST tropics.log"

NAME="perf"
STORE_PATH="/var/log/perf/"
LOG_PATH="/tmp/$NAME/"
PERF_PATH="C:\\perf"
TMP_STAF_LIST="/tmp/$RANDOM.staf_list"
VM_IP_LST=""
VM_SYS=""
VM_COUNT=0

#env judgement
func_env_check()
{
    local store_date="ww_"`date +%V`
    local xgt_flag vtd_flag nxgt_flag
    [ ! -f /var/run/xenstored.pid ] && echo "Miss XEN function, please check ENV"
    [[ `cat /proc/cmdline |grep '\.vgt=1'` ]] && xgt_flag=1 || xgt_flag=0
    [[ `cat /proc/cmdline |grep 'xen-pciback.hide=(00:02.0)'` ]] && vtd_flag=1 || vtd_flag=0
    [[ `cat /proc/cmdline |grep '\.vgt=0'` ]] && nxgt_flag=1 || nxgt_flag=0

    STORE_PATH="$STORE_PATH/$store_date"

    if [ $xgt_flag -eq 1 ];then
        STORE_PATH="$STORE_PATH/xgt"
    elif [ $vtd_flag -eq 1 ];then
        STORE_PATH="$STORE_PATH/vtd"
    elif [ $nxgt_flag -eq 1 ];then
        STORE_PATH="$STORE_PATH/nxgt/"
    else
        echo Detect xen flag meet some problem, need update script
        cat /proc/cmdline
        exit
    fi
}

func_check_ip()
{
    local idx=0 count=100 wait_t=10s
    while [ $idx -lt $count ];
    do
        staf_list.sh |sed "1,2d" > $TMP_STAF_LIST
        VM_IP_LST=`cat $TMP_STAF_LIST |awk '{print $6;}'`
        [[ ! `echo $VM_IP_LST|grep 'Miss_IP'` ]] && break
        idx=`expr $idx + 1`
        sleep $wait_t
        echo "loop catch all guest ip($idx/$count)"
    done

    [[ $idx -ge $count ]] && echo "catch guest ip failed, please check it" && cat $TMP_STAF_LIST && rm $TMP_STAF_LIST -f && exit

    local vm_ip 
    for vm_ip in `echo $VM_IP_LST`
    do
        idx=0
        while [ $idx -lt $count ];
        do
            staf_ping.sh $vm_ip
            [[ $? -eq 0 ]] && break
            sleep $wait_t
            idx=`expr $idx + 1`
            echo "ping $vm_ip failed($idx/$count)"
        done
        [[ $idx -ge $count ]] && echo "ping guest ip \"$vm_ip\" failed, please check it" && cat $TMP_STAF_LIST && rm $TMP_STAF_LIST -f && exit
    done
    [[ `cat $TMP_STAF_LIST|grep "unknow"` ]] && staf_list.sh |sed "1,2d" > $TMP_STAF_LIST
    [[ `cat $TMP_STAF_LIST|grep "file"` ]] && staf_list.sh |sed "1,2d" > $TMP_STAF_LIST
}

# OS type detect
func_os_detect()
{
    local _count=`cat $TMP_STAF_LIST|awk '{print $8;}'|uniq|wc -l`
    [ $_count -ne 1 ] && echo "multi system detect, please check it." && cat $TMP_STAF_LIST && rm -f $TMP_STAF_LIST && exit
    VM_SYS=`cat $TMP_STAF_LIST |awk '{print $8;}'|uniq`
    VM_COUNT=`cat $TMP_STAF_LIST |awk '{print $8;}'|wc -l`

    LOG_PATH="$LOG_PATH/$VM_SYS/$VM_COUNT"
    STORE_PATH="$STORE_PATH/$VM_SYS/$VM_COUNT"
    rm -rf $LOG_PATH
    mkdir -p $LOG_PATH
    mkdir -p $STORE_PATH
    rm -rf $TMP_STAF_LIST
}

# catch log
func_catch_log()
{
    local vm_ip=$1
    local path=$2
    for res in `echo $RESULT_LST`
    do
        staf_get.sh $vm_ip "$PERF_PATH\\$res" $path
        sleep 1s
    done
}

# analyze log
func_analyze_log()
{
    cd $1
    local store=$2
    #     3dmark06
    if [ -f 3dmark06.3dr ];then
        unzip 3dmark06.3dr << END
A
END
        xml2 < Result.xml |sed '/Setting/d;/@/d;/Status/d;/Category/d;/Plain/d;1d'|awk -F '=' '{print $2;}'|sed '/^$/d;/Score/,+1!d;/Game Score/,+1d;s:$:,:g'|grep -v 'Score'|grep -v '\-1'|sed 's/,//g' |tee $store/3dmark06.log
    fi

    #     heaven
    if [ -f heaven.log ];then
        sed -i 's/&nbsp;/ /g;s:<br/>:\n:g;s:</div>:\n:g' heaven.log
        cat heaven.log |grep 'Total'|grep 'FPS'|awk '{print $(NF-4);}'|tee $store/heaven.log
        cat heaven.log |grep 'Total'|grep 'scores'|awk '{print $NF;}'|tee -a $store/heaven.log
    fi

    #     passmark
    if [ -f passmark.log ];then
        cat passmark.log|sed 's/Graphics 2D -//g'|sed '3,11d;13,21d;23,$d' |sed 1d |awk -F ',' '{A+=$2;B+=$3;C+=$4;D+=$5;E+=$6;F+=$7;G+=$8;H+=$9}END{print H/NR"\n"A/NR"\n"B/NR"\n"C/NR"\n"D/NR"\n"E/NR"\n"F/NR"\n"G/NR}'|tee $store/passmark.log
    fi

    #     3dmark06
    if [ -f 3dmark11.3dr ];then
        unzip 3dmark11.3dr << END
A
END
        xml2 < Result.xml |grep 'primary_result'|awk -F '=' '{print $2;}'|sed '/FPS/d'|tee $store/3dmark11.log
        xml2 < Result.xml |grep 'results'|sed '/sets/d'|sed '1,5d;10,$d'|awk -F '=' '{print $2;}'|sed '1,2d;$d'|tee -a $store/3dmark11.log
    fi

    #    tropics
    if [ -f tropics.log ];then
        sed -i 's/&nbsp;/ /g;s:<br/>:\n:g;s:</div>:\n:g' tropics.log
        cat tropics.log |grep 'FPS'|grep -v 'Min'|grep -v 'Max'|awk -F ':' '{print $NF;}'|sed 's/[[:blank:]]//g'|tee $store/tropics.log
        cat tropics.log |grep 'Scores' |awk -F ':' '{print $NF;}'|sed 's/[[:blank:]]//g'|tee -a $store/tropics.log
    fi
}

func_generate_result_head()
{
    cat > $LOG_PATH/3dmark06.head.txt << END
SM2.0
HDR/SM3.0
END

    cat > $LOG_PATH/heaven.head.txt << END
FPS
Score
END

    cat > $LOG_PATH/passmark.head.txt << END
2D Graphics Mark
Simple Vectors
Complex Vectors
Fonts and Text
Windows Interface
Image Filters
Image Rendering
Direct 2D
END

    cat > $LOG_PATH/3dmark11.head.txt << END
Test1
Test2
Test3
Test4
Score
END

    cat > $LOG_PATH/tropics.head.txt << END
FPS
Score
END
}

func_run_child_app()
{
    local vm_ip=$1 app=$2
    echo `date +%T`" run $app in $vm_ip"
    staf_exec.sh $vm_ip "$PERF_PATH\\$app.bat"
    sleep 1m && exit
}

func_run_all()
{
    local vm_ip app
    for app in `echo $APP_LST`;
    do
        echo "Run $app for each $VM_SYS guest"
        for vm_ip in `echo $VM_IP_LST`;
        do
            func_run_child_app $vm_ip $app &
        done
        func_child_thread_lock
    done
    sleep 1m
}

# bash thread lock wait for guest run bat
func_child_thread_lock()
{
    local tmp_ps child_pid
    while [ true ];
    do
        tmp_ps=/tmp/$RANDOM.tmp.ps
        ps -ef > $tmp_ps
        [ ! -f $tmp_ps ] && echo "Some thing error" && pkill $0 && exit
        child_pid=`cat $tmp_ps |grep "$$"|grep -v 'ps'|awk '{print $2;}'|grep -v "$$"`
        [ ! "$child_pid" ] && echo "No child pid detected" && rm -rf $tmp_ps && break
        sleep 30s
        rm -rf $tmp_ps
    done
}

# catch log to local /tmp directory
func_catch_all_log()
{
    idx=1
    for vm_ip in `echo $VM_IP_LST`;
    do
        mkdir -p $LOG_PATH/$idx
        func_catch_log $vm_ip $LOG_PATH/$idx
        idx=`expr $idx + 1`
    done
}

# analyze & store log to /var/log/$NAME
func_generate_result_log()
{
    # create title for log file
    local idx=1 app log_flag app_file
    local tmp_file="$STORE_PATH/$NAME.csv"
    echo -ne 'Benchmark,' > $tmp_file
    while [ $idx -le $VM_COUNT ];
    do
        echo -ne "vm_$idx," >> $tmp_file
        idx=`expr $idx + 1`
    done
    echo "avg" >> $tmp_file

    idx=1
    while [ $idx -le $VM_COUNT ];
    do
        mkdir -p $STORE_PATH/$idx
        func_analyze_log $LOG_PATH/$idx $STORE_PATH/$idx
        idx=`expr $idx + 1`
    done

    # merge result log
    func_generate_result_head

    # add result
    cd $STORE_PATH
    for app in `echo $APP_LST`;
    do
        app_file=$LOG_PATH/$app.csv
        rm -rf $app_file
        log_flag=`find -name $app.log`
        [[ ! "$log_flag" ]] && rm -rf $LOG_PATH/$app.*.txt && continue
        paste -s -d "," `find -name $app.log`|awk -F "," '{for(i=1;i<=NF;i++) a[i]+=$i} END { for (i=1; i<=NF; i++) print a[i]/NR}' > $LOG_PATH/$app.avg.txt
        paste -d "," $LOG_PATH/$app.head.txt `find -name $app.log` $LOG_PATH/$app.avg.txt > $LOG_PATH/$app.result.txt
        cat $LOG_PATH/$app.result.txt >> $app_file
        rm -rf $LOG_PATH/$app.*.txt
    done
}

# dump the final result
func_dump_result()
{
    local app dump_wait=1m file=$STORE_PATH/$NAME.csv
    cd $LOG_PATH
    echo
    echo "store at $STORE_PATH wait $dump_wait dump the result:"
    sleep $dump_wait
    echo
    for app in `echo $APP_LST`;
    do
        [[ ! -f $app.csv ]] && continue
        echo
        echo $app result:
        echo $app >> $file
        cat $app.csv |tee -a $file
    done
}

#func_env_check
func_check_ip
#func_os_detect
# run programm
#func_run_all

func_catch_all_log
func_generate_result_log
func_dump_result
