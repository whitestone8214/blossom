#!/bin/bash


useradd -m -G audio,video,input user || exit -1
chown -R user:user /home/user || exit -1
passwd user
