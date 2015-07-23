#!/bin/bash

BUILD='./build'
OUT='./dist'
mkdir $BUILD
mkdir $OUT

cp -r ./server/src/* $OUT/

cp -r ./client/* $BUILD/
mv $BUILD/src/images $BUILD/images
mv $BUILD/src/fonts $BUILD/fonts

mtasc -swf $BUILD/src/classes.swf -frame 1 -header 320:200:31 -version 8 -v -strict -msvc -wimp -cp $BUILD/src $BUILD/src/App.as

swfmill -v simple $BUILD/src/application.xml $BUILD/client.swf
mv $BUILD/client.swf $OUT/html/client.swf

rm -rf $BUILD
