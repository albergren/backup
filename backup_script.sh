#!/bin/bash

. backup.conf

backup_created=false
backup_destination=""
identifier_name=".backup_dir"

function create_archive () {
    time=`date +%b-%d-%y`
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
	udisksctl mount -b $i  
    done
    sleep 5
}

function find_backup_location() {
    mount_point=/media/`whoami`
    for i in $mount_point/* ; do
	echo $identifier_name
	if [ -f $i/$identifier_name ] ; then
	    echo "success"
	    backup_destination=$i/
	    return 1;
	fi
    done
    echo "no show"
    return 0;

}
function remove_oldest_backup () {
    echo ""
	}

# If first run then initialize
if  [ ! -f $identifier_name ] ; then
    read -p "Enter path to location of backup on drive: " destination
    touch $destination/$identifier_name    
    touch $identifier_name
    
else   
    # find mountpont for drive and create archive. 
    find_backup_location
    if [ "$backup_destination"  ] ; then
	create_archive $backup_destination
	exit 1
    fi
    # If not found mount drives and try again.
    mount_drives
    find_backup_location
    if [ "$backup_destination"  ] ; then
	create_archive $backup_destination
	exit 1
    fi

fi
