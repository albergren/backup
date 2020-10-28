#!/bin/bash

. backup.conf

backup_created=false
backup_destination=""
identifier_name=".backup_identifier"

function create_archive () {
    time=`date +%G%m%d%H%M`
    filename=backup-$time.tar.gz 
    src_dirs=''

    for i in "${dir_paths[@]}"; do
    
	dir_path=$(dirname $i)
	dir_name=$(basename $i)
   
	src_dirs="$src_dirs -C  $dir_path $dir_name" 
    done

    tar -cpvzf $1$filename $src_dirs
    backup_created=true 

}


function mount_drives () {
    for i in /dev/sd[b-e][1-9]; do
	echo "Mounting connected drives..."
	udisksctl mount -b $i  
    done
    sleep 5
}

function find_backup_location() {
    mount_point=/media/`whoami`
    for i in $mount_point/* ; do
	if [ -f $i/$identifier_name ] ; then
	    echo "Backup drive found!"
	    backup_destination=$i/
	    return 1;
	fi
    done
    echo "Backup drive could not be found. Make sure drive is connected!"
    return 0;

}
function remove_oldest_backup () {
    backup_count=$(find $1backup-*.tar.gz | sort | wc -l)
    if (( $backup_count > $store_count ))  ; then
	oldest_backup=`find $1backup-*.tar.gz | sort | head -n1`
	rm $oldest_backup
    fi
}

# If first run then initialize
if  [ ! -f $identifier_name ] ; then
    read -p "Enter path to drive where backups will be stored: " destination
    touch $destination/$identifier_name    
    touch $identifier_name
    
else   
    # find mountpont for drive and create archive. 
    find_backup_location
    
    if [ "$backup_destination"  ] ; then
	echo "Creating archive..."
	create_archive $backup_destination
	echo "Archive created!"
	remove_oldest_backup  $backup_destination
	exit 1
    fi
    # If not found mount drives and try again.
    mount_drives
    find_backup_location
    
    if [ "$backup_destination"  ] ; then
	echo "Creating archive..."
	create_archive $backup_destination
	echo "Archive created!"
	remove_oldest_backup $backup_destination
	exit 1
    fi
fi
