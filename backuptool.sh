#!/bin/bash
#
# Backup Tool 2.0
#
# Programm von Netstack GmbH written by Andreas Pfeiffer
#
# Dieses Programm wurde für Datenbank backups mehrerer Datenbanken vorgesehen!
# Ab Version 1.2 gibt es auch MYSQL-Checks
# Ab Version 2.0 sind auch Ordnerbackups moeglich
#
################# CONFIG #####################

backupdir=/data/backup	 			# Verzeichniss wo die Backups abgelegt werden, es werden automatisch unterordner "mysql" und "files" erstellt.
datenbank=(dbname dbnam2)			# Datenbanken welche gesichert werden sollen
datadir=(/path/to/webdir1 /path/to/webdir2)	# Welche Ordner sollen gesichert werden
dbuser=DBUSER					# Datenbank User
dbpass=DBPASS					# Datenbank Passwort
date1=$(date +%a)				# Datumsformat welches an die Dateien angehangen wird
hostname=$(hostname -f)				# Hostname
mailsubject="MYSQL-Backup - $hostname"		# Mail Betreff
mailtext=/tmp/mailtext.txt 			# Mailtext zum Versand
email=EMAIL@ADRESSE	 			# Empfaenger der Status Mails
date2=$(date +%A" "%d.%m.%Y)			# Datum für E-Mail

################# CONFIG END #################

#Clear mailtext

echo " " > $mailtext;

#Aktuelles Datum
echo "#############################################################" >> $mailtext
echo "MYSQL Backup Script from $hostname - "$date2 >> $mailtext
echo "#############################################################" >> $mailtext
echo "" >> $mailtext

# Check Backupdir
if test -d $backupdir
then
        echo "";
else
        echo -n "Create Backupdirectory ... " >> $mailtext
        mkdir $backupdir
	if test -d $backupdir
	then
        	echo -n "done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n "Error - Cant create backupdirectory" >> $mailtext
		exit 1;
	fi

fi
# Check Backupdir for mysql
if test -d $backupdir/mysql
then
        echo "";
else
        echo -n "Create Backupdirectory for mysql ... " >> $mailtext
        mkdir $backupdir/mysql
	if test -d $backupdir/mysql
	then
        	echo -n "done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n "Error - Cant create backupdirectory for mysql" >> $mailtext
		exit 1;
	fi

fi

# Check Backupdir for files
if test -d $backupdir/files
then
        echo "";
else
        echo -n "Create Backupdirectory for files ... " >> $mailtext
        mkdir $backupdir/files
	if test -d $backupdir/files
	then
        	echo -n "done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n "Error - Cant create backupdirectory for files" >> $mailtext
		exit 1;
	fi

fi

######################
# Start Files backup #
######################

#count datadir's from config
countdir=${#datadir[*]};

for (( j=0; j<$countdir; j++ ))
do
	#reset Error Variable TODO Error handling
	error="0";
	filesdir=${datadir[$j]}
	#echo "";
	#make backup from files dir
	name=$(basename $filesdir)
	echo -n "make backup from $filesdir ..." >> $mailtext
	tar -Pczf  $backupdir/files/$name'_'$date1.tar.gz $filesdir
	if [ $? == "0" ]
	then
		echo -n " done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n " error" >> $mailtext
		echo "\n" >> $mailtext
	fi
done


######################
# Start MYSQL Backup #
######################

#clear mysql checkfile
echo "" > /tmp/mysqlcheck

#count databaeses from config
count=${#datenbank[*]};

for (( i=0; i<$count; i++ ))
do
	#reset Error Variable
	dumperror="0";

	db=${datenbank[$i]}
	echo " ";
	# Check MYSQL DB
		echo -n "Check Mysql Database: \"$db\" ... " >> $mailtext
		mysqlcheck -s -u$dbuser -p$dbpass $db >> /tmp/mysqlcheck

		if [ $? == "0" ]
		then
			mysqlcheck=$(cat /tmp/mysqlcheck)
			if [ -n "$mysqlcheck" ];
			then
				echo -n " Error -> Details am Ende der Mail" >> $mailtext
				echo "" >> $mailtext
			else
				echo -n " OK" >> $mailtext
				echo "" >> $mailtext
			fi
		else
			echo -n " Error " >> $mailtext
			echo "" >> $mailtext
		fi

	# Dump MYSQL DB
		echo -n "create dump for db: \"$db\" ... " >> $mailtext
		mysqldump -u$dbuser -p$dbpass --opt $db > $backupdir/mysql/$db'_'$date1.sql
		if [ $? == "0" ]
		then
			echo -n " done " >> $mailtext
			sqlfile=$backupdir/mysql/$db'_'$date1.sql
			echo " " >> $mailtext
		else
			echo -n " Error " >> $mailtext
			dumperror="1";
			echo " " >> $mailtext
		fi

	# Gzip MYSQL Dump
		echo -n "gzip dump for db: \"$db\" ... " >> $mailtext
		if [ $dumperror == "0" ]
		then
	                gzip -f -9 $sqlfile
	                if [ $? == "0" ]
	                then
	                        echo -n " done " >> $mailtext
	                        echo " " >> $mailtext
	                else
	                        echo -n " Error " >> $mailtext
	                        echo " " >> $mailtext
	                fi
		else
			echo -n " Error " >> $mailtext
			echo " " >> $mailtext
		fi




if [ -n "$mysqlcheck" ];
then

	echo " " >> $mailtext
	echo "##############################################################" >> $mailtext
	echo "Mysql Check Details: " >> $mailtext
	echo "##############################################################" >> $mailtext
	echo "" >> $mailtext
	cat /tmp/mysqlcheck >> $mailtext
fi

done

# Mailversand

cat $mailtext | mail -s "$mailsubject" $email

exit 0;
