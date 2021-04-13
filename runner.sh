#!/usr/bin/env bash

echo "BackupUtil running"

catch() {
	if [ "$1" -eq "23" ]; then
		echo "Ignoring error 23, as it is caused by rsync partial xfer"
	else
		echo "Error #$1 occurred on line $2:"
    		awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=$2 $0
		bash /mnt/backup/backupUtil.sh backupEndError $1 $2
		exit $1;
	fi
}

userExit() {
	echo "User exited script on line $1"
	bash /mnt/backup/backupUtil.sh backupUserStop
	exit 0;
}


# Check for new month
#bash /mnt/backup/backupUtil.sh newMonth
# Run rsync backup

# start from current PID
MYPID=$$
CRON_IS_PARENT=0
# this might return a list of multiple PIDs
CRONPIDS=$(ps ho %p -C crond)

CPID=$MYPID
while [ $CRON_IS_PARENT -ne 1 ] && [ $CPID -ne 1 ] ; do
        CPID_STR=$(ps ho %P -p $CPID)
        # the ParentPID came up as a string with leading spaces
        # this will convert it to int
        CPID=$(($CPID_STR))
        # now loop the CRON PIDs and compare them with the CPID
        for CRONPID in $CRONPIDS ; do
                [ $CRONPID -eq $CPID ] && CRON_IS_PARENT=1
                # we could leave earlier but it's okay like that too
        done
done

trap 'catch $? $LINENO' ERR
trap 'userExit $LINENO' INT

bash /mnt/backup/backupUtil.sh backupStart

if [ "$CRON_IS_PARENT" == "1" ]; then
	echo "Crontab running job; non-verbose"
	rsync -azpH  --partial --delete --ignore-errors --no-W /mnt/remote/ /mnt/backup/backups/current
else
	echo "Local running job; verbose output enabled"

	# NO-W version - delta compression enabled
	rsync -azpH  -v --partial --delete --no-W --ignore-errors --stats /mnt/remote/ /mnt/backup/backups/current

	# Delta compression disabled
	#rsync -avzpH  --partial --delete -v --ignore-errors /mnt/remote/ /mnt/backup/backups/current
fi

# Make backup and check regarding free space
#bash /mnt/backup/backupUtil.sh hardLink

bash /mnt/backup/backupUtil.sh backupEndClean
