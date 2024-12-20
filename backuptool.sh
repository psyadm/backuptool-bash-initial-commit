#!/bin/bash
# Backup Tool 0.3 - Lokale Speicherung
# Programm von Netstack GmbH

################# CONFIG #####################
hostname="$(hostname -f)"
backupdir="/local_backup/$hostname"
datadir=(/path/to/files /path/to/files/2)
datenbank=(dbname dbname2)
date1="$(date +%a)"
date2="$(date +%A %d.%m.%Y)"
dbuser="DBUSER"
dbpass="DBPASS"
email="monitor@example.com"
mailsubject="Backup - $hostname"
mailtext="/tmp/mailtext.txt"

################# FUNCTIONS #####################

log_message() {
    echo -e "$1" | tee -a "$mailtext"
}

send_mail() {
    (
        echo "To: $email"
        echo "Subject: $mailsubject"
        echo "Content-Type: text/plain"
        echo
        cat $mailtext
    ) | msmtp $email
}

check_and_install_package() {
    local pkg="$1"
    if ! dpkg -l | grep -q "$pkg"; then
        log_message "Installing $pkg..."
        sudo apt-get update && sudo apt-get install -y "$pkg"
        if [ $? -ne 0 ]; then
            log_message "Failed to install $pkg. Exiting..."
            send_mail
            exit 1
        fi
    fi
}

create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        if [ $? -ne 0 ]; then
            log_message "Error creating directory: $dir"
            send_mail
            exit 1
        fi
    fi
}

backup_files() {
    for dir in "${datadir[@]}"; do
        if [ -d "$dir" ]; then
            local sanitized_dir="${dir%/}"  # Entfernt abschließenden Slash
            local name="$(basename "$sanitized_dir")"  # Extrahiert den Ordnernamen
            if [ -z "$name" ]; then
                log_message "Error: Unable to extract directory name for path $dir."
                send_mail
                exit 1
            fi
            log_message "Backing up directory $dir to $backupdir/files/${name}_$date1.tar.gz..."
            tar -Pczf "$backupdir/files/${name}_$date1.tar.gz" "$dir" --ignore-failed-read --warning=no-file-changed
            if [ $? -ne 0 ]; then
                log_message "Error backing up $dir. Exiting..."
                send_mail
                exit 1
            fi
        else
            log_message "Error: Directory $dir does not exist. Skipping..."
        fi
    done
}

backup_mysql() {
    for db in "${datenbank[@]}"; do
        local dump_file="$backupdir/mysql/${db}_$date1.sql"
        log_message "Creating MySQL dump for database $db..."
        mysqldump -u"$dbuser" -p"$dbpass" --opt "$db" > "$dump_file"
        if [ $? -ne 0 ]; then
            log_message "Error creating MySQL dump for $db. Exiting..."
            send_mail
            exit 1
        fi
        log_message "Compressing dump file $dump_file..."
        gzip -f -9 "$dump_file"
        if [ $? -ne 0 ]; then
            log_message "Error compressing $dump_file. Exiting..."
            send_mail
            exit 1
        fi
    done
}

################# MAIN SCRIPT #####################

>"$mailtext" # Clear mail text
log_message "Starting backup script for $hostname on $date2"

check_and_install_package "msmtp"

create_directory "$backupdir"
create_directory "$backupdir/mysql"
create_directory "$backupdir/files"

backup_files
backup_mysql

log_message "Backup completed successfully."
send_mail
exit 0
