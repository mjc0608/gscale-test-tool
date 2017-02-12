from __future__ import with_statement
from fabric.api import *
from os import path
import time

env.hosts = ['root@10.0.0.22']
env.password = 'a'

base_dir = '/home/mochi/img'


def create(num):
    for i in range(int(num)):
        run('xl cre ' + path.join(base_dir, str.format('ubuntu-64/perf_{0}.hvm', i)))
        time.sleep(30)


def bridge():
    run(path.join(base_dir, 'xenbr.sh'))
    time.sleep(1)


def ip_list():
    stdout = run(path.join(base_dir, 'test-tools/tools/ip_list.sh'))
    with open('ip_list.txt', 'w') as f:
        f.write(stdout)


def restart():
    run('reboot')


def start(num=0):
    if num == 0:
        return
    bridge()
    create(num)
    ip_list()

if __name__ == '__main__':
    print(str.format('ubuntu-64/perf_{0}.hvm', 10))
