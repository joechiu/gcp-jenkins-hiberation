#!/bin/sh

GIT=cloud-platforms
DIR=/opt/gcp
cd /tmp
[ -d $DIR ] || sudo mkdir $DIR
[ -d $GIT ] && sudo rm -rf $GIT
git clone https://github.com/joehmchiu/$GIT.git
sudo cp -rf cloud-platforms/gcp/* /opt/gcp/.

