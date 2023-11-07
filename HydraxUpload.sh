#!/bin/bash
OFF='\e[0m'
BanLog='\e[1;97;107m'
BanText='\e[1;30;107m'
YOn_White='\e[1;97;43m'
U_Yellow='\e[4;33m'
BOn_White='\e[1;97;44m'

echo -e "${BanLog}###############################################################${OFF}"
echo -e "${BanLog}## ${BanText}Upload to ${BOn_White}HYDRAX${BanText} Free Video Hosting${BanLog}                       ##${OFF}"
echo -e "${BanLog}###############################################################${OFF}"
echo -e " "
start=$(date +%s)
walk_dir () {
    for pathname in "$1"/*; do
        if [ -d "$pathname" ]; then
            walk_dir "$pathname"
        else
            case "$pathname" in
                *.mp4|*.mkv)
                   mv "$pathname" /root/Upload/
            esac
        fi
    done
}
function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d:' $H
  [[ $M > 0 ]] && printf '%d:' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf ''
  printf '%d\n' $S
}

DOWNLOADING_DIR=/root/Finish
walk_dir "$DOWNLOADING_DIR"

cd /root/Upload
rename 's/ /./g' *
rename 's/[^a-zA-Z0-9.-]//g' *
banyak=$(ls | wc -l)
echo -e " >> ${BOn_White} HYDRAX ${OFF} ${YOn_White} Uploading ${OFF} ${U_Yellow}$banyak Movies${OFF}"
cc=1
for mov in $(ls); do
        case "$mov" in
                *.mp4|*.mkv)
                besaran=$(ls -lh $mov | awk '{print  $5}')
                echo -e " "
                echo -e " >> ${BanText}[$cc]${OFF} ${BOn_White} HYDRAX ${OFF} ${YOn_White} Uploading ${OFF} ${U_Yellow}$mov ($besaran)${OFF}"
                curl -F "file=@$mov" up.hydrax.net/a31e01ae9b6afc4d0ce238113ca580e6 > /dev/nul
                rm -rf "$mov"
                ((cc=cc+1))
        esac
done
end=$(date +%s)
aa=$(($end-$start))
bb=$(displaytime $aa)
echo -e " "
echo -e " >> ${BOn_White} HYDRAX ${OFF} ${YOn_White} Uploading ${OFF} ${U_Yellow}Finish.. $bb${OFF}"
echo -e "\n"
