#!/bin/sh

TASK=jenkins-ssl-exp
WORKDIR=/tmp/$TASK
SCRIPT=$WORKDIR/bin/alert-mail.pl

[ -d $WORKDIR ] || mkdir -p $WORKDIR
cp -rf * $WORKDIR/.
cd $WORKDIR

# prod cert info and alert
time ansible-playbook -i prod-hosts playbook.yml --extra-vars "env=prod"
$SCRIPT prod 

# non prod cert info and alert
# time ansible-playbook -i np-hosts playbook.yml --extra-vars "env=nonprod"
# $SCRIPT nonprod 


