#!/bin/bash

# UpStage Backup Script
# Author: Paul Rohrlach (aut.upstage.team@gmail.com)
# Backups up all media from every server on system and archives it in /home/
# Should be placed in /usr/local/bin and added to crontab

cd /usr/local/share/upstage/

FILENAME=$(date +"%d-%m-%Y").tar

tar -cv -f $FILENAME *
gzip -v9 $FILENAME

FILENAME=($FILENAME.gz)

if [ -d /home/UpStage\ Media\ Backups/ ]; 
then	
	mv $FILENAME /home/UpStage\ Media\ Backups/
else
	mkdir /home/UpStage\ Media\ Backups/
	mv $FILENAME /home/UpStage\ Media\ Backups/
fi