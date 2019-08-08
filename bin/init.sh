#!/bin/sh

TASK=$1
DIR=/opt/$TASK
TASKDIR=/tmp/env/$TASK
sudo rm -rf $DIR
sudo mkdir -p $DIR
[ -d $TASKDIR ] || mkdir -p $TASKDIR

sleep 1

cat <<EOF > $TASKDIR/$TASK.inc
# setup global env variables for $TASK
TASK=$1
EOF

