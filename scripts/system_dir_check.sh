#!/bin/bash

bghome="/home/BGhome"
bgsftp="/home/BGsftp"
bgview="/home/BGsftp/view"
bgtickets="/home/BGsftp/tickets"
bgwsa="/home/BGsftp/wsa_download"
bgftp_transfer="/home/BGsftp/ftp_transfer"

ln_bghome="/BGhome"
ln_bgsftp="/BGsftp"

subnode="/BGlog/sub_node.ext"
bgdata="/BGlog/BGdata"
ln_bgdata="/BGdata"

home_dir_list=("$bghome" "$bgsftp" "$bgview" "$bgtickets" "$bgwsa" "$bgftp_transfer")
bglog_dir_list=("$subnode" "$bgdata")
ln_dir_list=("$ln_bghome" "$ln_bgsftp" "$ln_bgdata")


#check home dir
for dir in ${home_dir_list[@]}; do
    if [ ! -d $dir ]; then
        echo "$dir doesn't exists."
        exit 1
    fi
done

#check bglog dir
for dir in ${bglog_dir_list[@]}; do
    if [ ! -d $dir ]; then
        echo "$dir doesn't exists."
        exit 1
    fi
done

#check link dir
for dir in ${ln_dir_list[@]}; do
    if [ ! -L $dir ]; then
        echo "$dir doesn't exists."
        exit 1
    fi
done

exit 0

