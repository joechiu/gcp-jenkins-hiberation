#!/bin/sh

MSG=$1
echo -e $(date +'[%Y-%m-%d %H:%M:%S]')'\t'$MSG >> /tmp/ansible-jenkins-vms.log
