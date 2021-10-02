#!/bin/bash
 

conf_path="$(dirname "$0")/backup.conf"
. $conf_path
backup_destination=""
identifier_name=".backup_identifier"
mounted_drives=""

function create_archive () {
    time=`date +%G%m%d%H%M`
    filename=backup-$time.tar.gz 
    src_dirs=""

    for i in "${dir_paths[@]}"; do
    
	dir_path=$(dirname $i)
	dir_name=$(basename $i)
   
	src_dirs="$src_dirs -C  $dir_path $dir_name" 
    done
    
    echo "Creating archive..."
    tar -cpvzf $1$filename $src_dirs
    echo "Archive created!"


}


function mount_drives () {
    echo "Mounting connected drives..."
    for i in /dev/sd[b-e][1-9]; do
	udisksctl mount -b $i 2> /dev/null
	if [ $? -eq 0 ] ; then
	    mounted_drives="$mounted_drives $i"
       	fi
    done
}


function unmount_drives () {
    for i in $mounted_drives; do
	echo "Unmounting drives..."
	udisksctl unmount -b $i  
    done
}


function find_backup_location() {
    mount_point=/media/`whoami`
    for i in $mount_point/* ; do
	if [ -f $i/$identifier_name ] ; then
	    backup_destination=$i/
	    return 0;
	fi
    done
    return 1;

}


function remove_oldest_backup () {
    backup_count=$(find $1backup-*.tar.gz 2> /dev/null | wc -l)
    if (( $backup_count > $store_count ))  ; then
	oldest_backup=`find $1backup-*.tar.gz | sort | head -n1`
	rm $oldest_backup
    fi
}


function check_backup_exists (){
    backup_today_count=$(find $1backup-`date +%G%m%d`*.tar.gz 2> /dev/null | wc -l)
    if (( $backup_today_count > 0 ))  ; then
	echo "Backup already exists!"
	unmount_drives
	exit 0
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
	check_backup_exists $backup_destination
	create_archive $backup_destination
	remove_oldest_backup  $backup_destination
	exit 0
    fi
    # If not found, mount drives and try again.
    mount_drives
    find_backup_location
    
    if [ "$backup_destination"  ] ; then
	check_backup_exists $backup_destination
	create_archive $backup_destination
	remove_oldest_backup $backup_destination
	unmount_drives
	exit 0
    fi
    unmount_drives
fi
