#!/bin/bash
#
# BackupNFS Tool 0.2
#
# Programm von Netstack GmbH written by Andreas Pfeiffer
#
# Dieses Programm führt Datei Backups zu einem NFS Share durch
#
################# CONFIG #####################

backupdir="$nfsmountdir/$hostname"               # Verzeichniss wo die Backups abgelegt werden, es werden automatisch unterordner "mysql" und "files" erstellt.
datadir=(/path/to/files /path/to/files/2 )       # Welche Ordner sollen gesichert werden
datenbank=(dbname dbnam2)                        # Datenbanken welche gesichert werden sollen
date1=$(date +%a)                                # Datumsformat welches an die Dateien angehangen wird
hostname=$(hostname -f)                          # Hostname
dbuser=DBUSER                                    # Datenbank User
dbpass=DBPASS                                    # Datenbank Passwort
mailsubject="Backup - $hostname"                 # Mail Betreff
mailtext=/tmp/mailtext.txt                       # Mailtext zum Versand
email=monitor@example.com                        # Empfaenger der Status Mails
date2=$(date +%A" "%d.%m.%Y)                     # Datum für E-Mail
nfsmount="192.168.0.1:/backupshare"              # NFS server + mount mount
nfsmountdir=/path/to/backup/                     # Ordner fuer NFS-Share

################# CONFIG END #################

# Function to check if NFS packages are installed
check_nfs_packages() {
    if ! dpkg -l | grep -q nfs-common; then
        echo "NFS packages not installed. Installing..."
        sudo apt-get update
        sudo apt-get install -y nfs-common
        if [ $? -ne 0 ]; then
            echo "Failed to install NFS packages. Exiting..."
            exit 1
        fi
    fi
}

# Run the NFS package check function
check_nfs_packages

# Reset Error Variable
error="0"

# Clear mailtext
echo " " > $mailtext

# Aktuelles Datum
echo "#############################################################" >> $mailtext
echo "Backup Script from $hostname - $date2" >> $mailtext
echo "#############################################################" >> $mailtext
echo "" >> $mailtext

# Check Backupdir
if [ ! -d $nfsmountdir ]; then
    echo -n "Create Backupdirectory ... " >> $mailtext
    mkdir -p $nfsmountdir
    if [ ! -d $nfsmountdir ]; then
        echo -n "Error - Cant create nfs directory" >> $mailtext
        # send mail on Error 
        cat $mailtext | mail -s "$mailsubject" $email
        exit 1
    fi
    echo -n "done" >> $mailtext
    echo "\n" >> $mailtext
fi

# Mount NFS to backupdir
echo -n "mount nfs share $nfsmount ... " >> $mailtext
mount $nfsmount $nfsmountdir
if [ $? -ne 0 ]; then
    echo -n " error" >> $mailtext
    echo "\n" >> $mailtext
    # send mail on Error 
    cat $mailtext | mail -s "$mailsubject" $email
    exit 1
fi
echo -n " done" >> $mailtext
echo "\n" >> $mailtext

# Check Backupdir
if [ ! -d $backupdir ]; then
    echo -n "Create Backupdirectory ... " >> $mailtext
    mkdir -p $backupdir
    if [ ! -d $backupdir ]; then
        echo -n "Error - Cant create backupdirectory" >> $mailtext
        # send mail on Error 
        cat $mailtext | mail -s "$mailsubject" $email
        exit 1
    fi
    echo -n "done" >> $mailtext
    echo "\n" >> $mailtext
fi

# Check Backupdir for mysql
if [ ! -d $backupdir/mysql ]; then
    echo -n "Create Backupdirectory for mysql ... " >> $mailtext
    mkdir -p $backupdir/mysql
    if [ ! -d $backupdir/mysql ]; then
        echo -n "Error - Cant create backupdirectory for mysql" >> $mailtext
        # send mail on Error 
        cat $mailtext | mail -s "$mailsubject" $email
        exit 1
    fi
    echo -n "done" >> $mailtext
    echo "\n" >> $mailtext
fi

# Check Backupdir for files
if [ ! -d $backupdir/files ]; then
    echo -n "Create Backupdirectory for files ... " >> $mailtext
    mkdir -p $backupdir/files
    if [ ! -d $backupdir/files ]; then
        echo -n "Error - Cant create backupdirectory for files" >> $mailtext
        # send mail on Error 
        cat $mailtext | mail -s "$mailsubject" $email
        exit 1
    fi
    echo -n "done" >> $mailtext
    echo "\n" >> $mailtext
fi

######################
# Start Files backup #
######################

# Count datadir's from config
countdir=${#datadir[*]}

for (( j=0; j<$countdir; j++ ))
do
    filesdir=${datadir[$j]}
    # echo "";
    # Make backup from files dir
    name=$(basename $filesdir)
    echo -n "make backup from $filesdir ..." >> $mailtext
    tar -Pczf $backupdir/files/${name}_$date1.tar.gz $filesdir
    if [ $? -ne 0 ]; then
        echo -n " error" >> $mailtext
        echo "\n" >> $mailtext
        # send mail on Error 
        cat $mailtext | mail -s "$mailsubject" $email
        exit 1
    fi
    echo -n " done" >> $mailtext
    echo "\n" >> $mailtext
done

# Umount NFS share
umount $nfsmountdir

# Mailversand
# cat $mailtext | mail -s "$mailsubject" $email

exit 0
