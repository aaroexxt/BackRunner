#!/usr/bin/env bash

# modified from: https://www.howtoforge.com/tutorial/raspberry-pi-as-backup-server-for-linux-and-windows/

basePath="/mnt/backup/backups"
drive="/mnt/backup"

action="${1}"

function checkMonth ()
{
        now=$(date +"%Y-%m")
        last=$(<${drive}/checkMonth.txt)
        if [[ ${now} != ${last} ]]
        then
                # New Month
		echo "BackupUtil - new month"
                mkdir -p "${basePath}/current/"
                rm -Rf "${basePath}/current/"*
                echo "${now}" > "${drive}/checkMonth.txt"
	else
		echo "BackupUtil - not new month - syncing"
        fi
}



function makeHardlink ()
{
	echo "Hardlinking copy"
       # Make hardlink copy
        now=$(date +"%Y-%m-%d_%H-%M")
        mkdir -p "${basePath}/old/${now}"
        cp -al "${basePath}/current"* "${basePath}/old/${now}"
	echo "Copy hardlinked to ${basePath}/old/${now}"
}



function checkFree ()
{
	echo "Checking disk space..."
        # Check if old files need to be deleted
        freeSpace=$( df -P | grep "${drive}" | awk '{print $4}' )
        curUse=$( cd "${basePath}/current" | du -s | awk '{print $1}' )
        estUse=$(( curUse * 2 ))

        echo "Free: ${freeSpace} - CurrentUsed: ${curUse} - EstimatedUse: ${estUse}"
	
        while [[ ${freeSpace} -le ${estUse} ]]
        do
                echo "Not enough space... removing old backups..."
                IFS= read -r -d $'\0' line < <(find "${basePath}/old" -type d -maxdepth 1 -printf '%T@ %p\0' 2>/dev/null | sort -z -n)
                oldDir="${line#* }"                
		rm -Rf "${oldDir}"
                freeSpace=$( df -P | grep "${basePath}" | awk '{print $4}' )
                echo "After deleting, Free: ${freeSpace} - CurrentUsed: ${curUse} - EstimatedUse: ${estUse}"
	done
}



case ${action} in

        newMonth)
                        checkMonth
                        ;;
        hardLink)
                        makeHardlink
                        checkFree
                        ;;
esac
