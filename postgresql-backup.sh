#!/bin/bash
#
# Backup Tool 0.3
#
# Programm von Netstack GbR written by Andreas Pfeiffer
#
# Dieses Programm wurde für PostgreSQL Datenbank backups mehrerer Datenbanken vorgesehen!
#
################# CONFIG #####################

backupdir=/path/to/backupdir			# Verzeichniss wo die Backups abgelegt werden, es werden automatisch unterordner "mysql" und "files" erstellt.
datenbank=(db1 db2 db3)				# Datenbanken welche gesichert werden sollen
date1=$(date +%u)				# Datumsformat welches an die Dateien angehangen wird
hostname=$(hostname -f)				# Hostname
mailsubject="Postgres-Backup - $hostname"	# Mail Betreff
mailtext=/tmp/mailtext.txt 			# Mailtext zum Versand
email=email@example.com 			# Empfaenger der Status Mails
date2=$(date +%A" "%d.%m.%Y)			# Datum für E-Mail

################# CONFIG END #################

#Clear mailtext

echo " " > $mailtext;

#Aktuelles Datum
echo "#############################################################" >> $mailtext
echo "Postgres Backup Script from $hostname - "$date2 >> $mailtext
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
# Check Backupdir for postgresql
if test -d $backupdir/postgresql
then
        echo "";
else
        echo -n "Create Backupdirectory for postgresql ... " >> $mailtext
        mkdir $backupdir/postgresql
	if test -d $backupdir/postgresql
	then
        	echo -n "done" >> $mailtext
		echo "\n" >> $mailtext
	else
		echo -n "Error - Cant create backupdirectory for postgresql" >> $mailtext
		exit 1;
	fi

fi

###########################
# Start PostgreSQL Backup #
###########################


#count databaeses from config
count=${#datenbank[*]};

for (( i=0; i<$count; i++ ))
do
	#reset Error Variable
	dumperror="0";

	db=${datenbank[$i]}
	echo " ";
	# Dump PostgreSQL DB
		echo -n "create dump for db: \"$db\" ... " >> $mailtext
			pg_dump -Fc $db > $backupdir/postgresql/$db'_'$date1.sql
		if [ $? == "0" ]
		then
			echo -n " done " >> $mailtext
			sqlfile=$backupdir/postgresql/$db'_'$date1.sql
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
done



# Mailversand

cat $mailtext | mail -a "From: SERVERNAME <example@example.com>" -s "$mailsubject" $email

exit 0;
