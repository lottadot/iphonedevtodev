#!/bin/sh

export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate
codesign -f -s "iPhone Developer" APPNAME
