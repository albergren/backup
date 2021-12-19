#!/bin/bash

conf_path="$(dirname "$0")/backup.conf"
. $conf_path
backup_destination=""

function create_archive () {
    time=`date +%G%m%d%H%M`
    filename=backup-$time.tar.gz
    src_dirs=""
    
    for i in "${source_paths[@]}"; do
        dir_path=$(dirname $i)
        dir_name=$(basename $i)

        src_dirs="$src_dirs -C  $dir_path $dir_name"
    done

    tar -cpvzf $1$filename $src_dirs


}

function remove_oldest_backup () {
    backup_count=$(find $1backup-*.tar.gz 2> /dev/null | wc -l)
    if (( $backup_count > $store_count ))  ; then
        oldest_backup=`find $1backup-*.tar.gz | sort | head -n1`
        rm $oldest_backup
    fi
}

create_archive $target_path
remove_oldest_backup
