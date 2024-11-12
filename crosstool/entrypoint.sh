#!/bin/bash
uid=${UID:-1000}
gid=${GID:-1000}
useradd -u $uid -g $gid user
sudo -s -u user "$@"
