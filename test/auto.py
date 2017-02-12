import os
import time

for num in (1,2,3,5,10,15):
    while os.system('ping 10.0.0.22 -c 1') != 0:
        print('the remote host is not up, sleep 5 seconds')
        time.sleep(5)

    print("***********************************************************************************************")
    command = str.format('fab start:num={0} -f machine.py', num)
    print("run command: " + command)
    os.system(command)

    print("***********************************************************************************************")
    command = str.format('fab ip animation -f animate.py > log{0}.txt', num)
    print("run command: " + command)
    os.system(command)

    print("***********************************************************************************************")
    command = 'fab restart -f machine.py'
    print("run command: " + command)
    os.system(command)

    time.sleep(90)
