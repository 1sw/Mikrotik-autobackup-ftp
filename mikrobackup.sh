#!/bin/bash

#
# Mikrotik FTP backup script rev. 3.4
#
# Copyright (C) 2014 Petr Domorazek <petr@domorazek.cz>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#


LOCAL_DIR=`dirname $0`
HOST=`hostname`
BACKUP_PATH=/home/backup/mikrotik
CONF=$LOCAL_DIR/mikrobackup.conf
LOG=$BACKUP_PATH/mikrobackup`date +%Y%m%d`.log
FTP_USER=backup
FTP_PASS=1234
DELETE_FILE=yes
MAIL_FROM=support@firma.cz
MAIL_TO=admin@firma.cz

if [ ! -f "$CONF" ] 2>/dev/null ; then
    echo "ERROR, Configuration file not found!"
    exit 1
fi
if  [ ! -d "$BACKUP_PATH" ] ; then
    echo "ERROR, Backup path not found!"
    exit 1
fi
LAST_CHAR=`tail -c 1 $CONF`
if [ "$LAST_CHAR" != "" ] ; then
    echo -e "" >> $CONF
fi
ERROR_FTP=no

while read -r line
do 
    line=`echo $line | grep :`
    if [ -n "$line" ] ; then
        if [ "${line:0:1}" != "#" ] ; then
            IP=`echo $line | cut -d: -f1 | tr -d " "`
            DESC=`echo $line | cut -d: -f2 | tr -d " "`
            echo $IP - $DESC
            if  [ ! -d "${BACKUP_PATH}/${DESC}" ] ; then
                mkdir -p ${BACKUP_PATH}/${DESC}
            fi
            for FTPFILE in zaloha.backup zaloha.rsc
            do
                response=$(curl --connect-timeout 120 -w %{http_code} -s -o ${BACKUP_PATH}/${DESC}/`date +%Y%m%d`${FTPFILE} ftp://${IP}/${FTPFILE} --user ${FTP_USER}:${FTP_PASS})
                if [ $response -eq "226" ] ; then
                    echo "$IP - FTP:$response File $FTPFILE download successful."
                    if [ "$DELETE_FILE" == "yes" ] ; then
                        curl --connect-timeout 60  -s ftp://${IP}/${FTPFILE} --user ${FTP_USER}:${FTP_PASS} -O --quote "DELE /${FTPFILE}"
                        echo "$IP - FTP:Deleting file ${FTPFILE} from FTP."
                    fi
                else
                    echo -e "$IP - FTP:$response \e[31mERROR\e[0m, Can not download $FTPFILE file."
                    echo -e "`date "+%Y-%m-%d %T"` \t  $IP \t  $DESC \t  FTP Error Code: $response - Can not download $FTPFILE file." >> $LOG
                    ERROR_FTP=yes
                fi
            done
        fi
    fi
done < $CONF
if [ "$ERROR_FTP" == "yes" ] ; then
    echo -e ""
    echo -e "\e[31m!!!ERROR\e[0m - When backing up the \e[31mERROR\e[0m occurred."
    echo -e "`date "+%Y-%m-%d %T"` \t  !!!ERROR - When backing up the ERROR occurred." >> $LOG
    echo -e "Check the log file: $LOG"
    echo -e "!!!ERROR - When backing up the ERROR occurred.\nCheck the $HOST server log file: $LOG" | mail -s "Server: $HOST - Backup Mikrotiks ended with ERRORS!" -r $MAIL_FROM $MAIL_TO
else
    echo -e ""
    echo -e "\e[32mOK\e[0m - The backup is complete."
    echo -e "`date "+%Y-%m-%d %T"` \t  OK - The backup is complete." >> $LOG
fi