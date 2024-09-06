#!/bin/bash
#
# Gitlab Backup Tool 1.0
#
# Programm von Netstack GmbH written by Andreas Pfeiffer
#
# Dieses Programm wurde für GitLab backups mehrerer vorgesehen!

#
################# CONFIG #####################

backupdir=/data/backup/gitdocker/gitlab		# Verzeichniss wo die Backups abgelegt werden, es werden automatisch unterordner "mysql" und "files" erstellt.
date1=$(date +%d_%m_%Y)				        # Datumsformat welches an die Dateien angehangen wird
hostname=$(hostname -f)				        # Hostname
mailsubject="Backup - $hostname"            # Mail Betreff
mailtext=/tmp/mailtext.txt 			        # Mailtext zum Versand
email=sample@example.com    		        # Empfaenger der Status Mails
date2=$(date +%A" "%d.%m.%Y)		    	# Datum für E-Mail
nfsmount="SERVER_IP:/NFS-FOLDER"		    # NFS server + mount mount
nfsmountdir=/data/backup/			        # Ordner fuer NFS-Share

################# CONFIG END #################

#Clear mailtext

echo " " > $mailtext;

#Aktuelles Datum
echo "#############################################################" >> $mailtext
echo "Backup Script from $hostname - "$date2 >> $mailtext
echo "#############################################################" >> $mailtext
echo "" >> $mailtext

# Check Backupdir
if test -d $nfsmountdir
then
        echo "";
else
        echo -n "Create Backupdirectory ... " >> $mailtext
        mkdir -p $nfsmountdir
        if test -d $nfsmountdir
        then
                echo -n "done" >> $mailtext
                echo "\n" >> $mailtext
        else
                echo -n "Error - Cant create nfs directory" >> $mailtext
                exit 1;
        fi

fi

#mount NFS to backupdir
echo -n "mount nfs share $nfsmount ... " >> $mailtext;
mount $nfsmount $nfsmountdir
if [ $? == "0" ]
then
	echo -n " done" >> $mailtext
	echo "\n" >> $mailtext
else
	echo -n " error" >> $mailtext
	echo "\n" >> $mailtext
fi

# Check Backupdir
if test -d $backupdir
then
        echo "";
else
        echo -n "Create Backupdirectory ... " >> $mailtext
        mkdir -p $backupdir
	if test -d $backupdir
	then
        	echo -n "done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n "Error - Cant create backupdirectory" >> $mailtext
		exit 1;
	fi

fi



######################
# Start Files backup #
######################

echo -n "Gitlab Backup ..." >> $mailtext;
gitlab-backup create SKIP=artifacts,uploads,registry && cd /var/opt/gitlab/backups && mv $(ls -t | head -n1) $backupdir
if [ $? == "0" ]
then
	echo -n " done" >> $mailtext
	echo "\n" >> $mailtext
else
	echo -n " error" >> $mailtext
fi

cp /etc/gitlab/gitlab.rb $backupdir/gitlab.rb_$date1

#umount NFS share
umount $nfsmountdir

# Mailversand

cat $mailtext | mail -s "$mailsubject" $email

exit 0;