
![Packagist](https://img.shields.io/packagist/l/doctrine/orm.svg)


# Backuptool for Webdir's and MySql-Databases

you can backup some webdirectory's and some mysql-databases. 


## Config 

The backtool.sh Script has a config part on top. 

```Shell
################# CONFIG #####################

backupdir=/path/to/backup			 		# Verzeichniss wo die Backups abgelegt werden, es werden automatisch unterordner "mysql" und "files" erstellt.
datenbank=(database01 database02)				# Datenbanken welche gesichert werden sollen
datadir=(/path/to/webdir1 /path/to/webdir2)			# Welche Ordner sollen gesichert werden
dbuser=DBUSER							# Datenbank User
dbpass=DBPASS							# Datenbank Passwort
date1=$(date +%a)						# Datumsformat welches an die Dateien angehangen wird
hostname=$(hostname -f)						# Hostname
mailsubject="MYSQL-Backup - $hostname"				# Mail Betreff
mailtext=/tmp/mailtext.txt 					# Mailtext zum Versand
email=test@email.de	 					# Empfaenger der Status Mails
date2=$(date +%A" "%d.%m.%Y)					# Datum für E-Mail

################# CONFIG END #################
```
