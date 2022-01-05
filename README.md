# BackRunner
 Utility to routinely backup local file server to store, and automatically manage monthly backups

# Setup
Here's a brief overview of the setup process I'm using:

- Install NTFS-3g with `sudo apt-get install -y ntfs-3g`
- Run `sudo blkid` to get UUID of local drive
- Run `sudo mkdir /mnt/backup && sudo mkdir /mnt/remote` to create paths to mount things

#### Mounting
First, make sure that you've mounted both your remote drive and local drive to `/mnt/remote` and `/mnt/backup`, respectively

Example fstab command for loading remote store:

`//192.168.1.169/home /mnt/remote cifs vers=1.0,user=ExampleUser,password=ExamplePassword,x-systemd.automount,ro 0 0`

#### Running Locally
The first time I'm running the script, I like to run it locally. The following command will do so:

`sudo nohup sudo rm /mnt/backup/log.txt ; sudo bash /mnt/backup/runner.sh > log.txt 2>&1 &`

This command will add all output to `log.txt`, a local file that you can then read remotely to ensure that it is working. All output will be appended there, including rsync's output in verbose mode.

#### Setting up Crontab

Of course, you want to reconfigure this to work on your system, but here's how I have my crontab set up:
```
MAILTO=johndoe@example.com

26 5 * * * /bin/bash /mnt/backup/runner.sh
```

This will run the backup every day at 5:26AM (frc team heh)

In addition, it will email me the output when it is finished. The script automatically detects that cron is running it and turns off rsync verbose mode.

#### Retreiving the Backup

Oh no! What if your files are gone?

Well, this hasn't happened to me yet, so I might update this if it does, but here's one command that could be used to transfer files over secure shell (*note: untested*). Alternatively, you could use rsync.

`scp -r pi@192.168.1.71:/mnt/backup .`

Finally, here's the command I use to copy all the remote files of importance to my desktop:

`scp -r pi@192.168.1.71:/mnt/backup/\{runner.sh,backupUtil.sh,runLog.txt} ./`
