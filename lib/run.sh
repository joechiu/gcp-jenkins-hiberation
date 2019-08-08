#!/bin/sh

BIN=/opt/bin
[ -d $BIN ] || sudo mkdir $BIN
cp -rf ./bin/* $BIN/.
chmod 755 $BIN/*
