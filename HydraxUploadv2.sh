#!/bin/bash
OFF='\e[0m'
BanLog='\e[0;97;107m'
BanText='\e[0;30;107m'
BWhite='\e[1;37m'
BYellow='\e[4;33m'
On_White='\e[1;30;43m'
On_Red='\e[1;30;41m'
On_Blue='\e[1;97;44m'
On_Yellow='\e[1;97;43m'
On_Green='\e[1;97;42m'

echo -e "${BanLog}###############################################################${OFF}"
echo -e "${BanLog}## ${BanText}Upload to Free Video Hosting${BanLog}                              ##${OFF}"
echo -e "${BanLog}###############################################################${OFF}"
echo -e " "

hydraxuploading(){
        echo -ne "       ${On_Blue} HYDRAX ${OFF} ${On_Yellow} Uploading: ${OFF} ${BYellow} \r"
        for file in $(ls *.mp4)
                do
                        echo -ne "${OFF}       ${On_Blue} HYDRAX ${OFF} ${On_Yellow} Uploading: ${OFF} ${BYellow}"
                        echo -ne " $file "
                        echo -ne "${OFF}${BWhite} Please Wait..!${OFF}\r\n"
                        curl -F "file=@$file" up.hydrax.net/aaaaaaaaaaaaaaaaaaaa > /dev/null
                done
        echo -ne "\n"
        echo -e "       ${On_Blue} HYDRAX ${OFF} ${On_Green} Selesai ! ${OFF}\n"
}

hydraxuploading
