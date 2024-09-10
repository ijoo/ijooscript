#!/bin/bash
DL_PATH="/home/ijoo/DL"
UP_PATH="/home/ijoo/Upload"
ID_Filemoon="ftp://ijoo:19qdf1cqu9@ftp.filemoon.sx"
ID_StreamWish="ftp://ijoo:ee7jy1v5zy@ftp.streamwish.com"
ID_VidHide="ftp://ijoo:c827j93yck@vidhideftp.com"

OFF='\e[0m'
BanLog='\e[1;97;107m'
BanText='\e[1;30;107m'
RedText='\e[1;30;31m'
BoldWhite='\e[1;97m'
YOn_White='\e[1;97;43m'
U_Yellow='\e[4;33m'
BOn_White='\e[1;97;44m'

echo -e "${BanLog}###############################################${OFF}"
echo -e "${BanLog}## ${BanText}Torrent Download and Uploaded               ${OFF}"
echo -e "${BanLog}## ${BanText}This Code Private, Created For ${RedText}Flix21       ${OFF}"
echo -e "${BanLog}###############################################${OFF}"

if [ -x "/usr/local/bin/torrent-dl" ]; then
   echo " "
else
   echo "Cannot Found Torrent-dl"
   exit
fi

echo -e "${BoldWhite} >> Masukan Link Torrent / Magnet : ${OFF}"
echo -e "${BoldWhite} >>${OFF} \c"
read torurl

cd "$DL_PATH"
torrent-dl -i "$torurl"

walk_dir () {
    for pathname in "$1"/*; do
        if [ -d "$pathname" ]; then
            walk_dir "$pathname"
        else
            case "$pathname" in
                *.mp4|*.mkv|*.srt)
                   mv "$pathname" "$UP_PATH"
            esac
        fi
    done
}

walk_dir "$DL_PATH"

cd $UP_PATH
rename 's/ /./g' *
rename 's/[^a-zA-Z0-9.-]//g' *
echo -e " "
for mov in $(ls); do
   case "$mov" in
        *.mp4|*.mkv)
        besaran=$(ls -lh $mov | awk '{print  $5}')
        echo -e "${BoldWhite} >>${OFF} ${BOn_White} FILEMOON ${OFF} ${YOn_White}Uploading ${OFF} ${U_Yellow}$mov ($besaran)${OFF}"
        curl -T "$mov" "$ID_Filemoon" > /dev/null

        echo -e "${BoldWhite} >>${OFF} ${BOn_White} STREAMWISH ${OFF} ${YOn_White}Uploading ${OFF} ${U_Yellow}$mov ($besaran)${OFF}"
        curl -T "$mov" "$ID_StreamWish" > /dev/null

       echo -e "${BoldWhite} >>${OFF} ${BOn_White} VIDHIDE ${OFF} ${YOn_White}Uploading ${OFF} ${U_Yellow}$mov ($besaran)${OFF}"
        curl -T "$mov" "$ID_VidHide" > /dev/null

        rm -rf "$mov"
   esac
done

cd "$DL_PATH"
rm -rf *

echo -e " "
echo -e "${BanLog}## ${BanText}Selesai...!                                 ${OFF}"
echo -e " "
