from __future__ import with_statement
from fabric.api import *
from os import path


env.hosts = []
env.password = '123456'

bash_dir = '/home/mochi'


def ip():
    with open('ip_list.txt', 'r') as f:
        for line in f:
            if line.strip() == '10.0.0.22':
                continue
            if line.startswith('10.0.0.'):
                env.hosts.append('root@' + line.strip())


@parallel(pool_size=20)
def animation():
    run("/mnt/run3d_test.sh warsow")


if __name__ == '__main__':
    pass
