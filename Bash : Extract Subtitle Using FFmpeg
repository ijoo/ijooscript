#!/bin/bash
# see index
# ffprobe -v error -of json input.mkv -of json -show_entries "stream=index:stream_tags=language" -select_streams s
# ffmpeg -i input.mkv -map "0:index-no" output.eng.srt
#
# remote html tag , sed -e 's/<[^>]*>//g' subs.srt

OFF='\e[0m'
BWhite='\e[1;37m'
On_White='\e[1;30;43m'
On_Red='\e[1;30;41m'

echo -e "${BWhite}###############################################################"
echo -e "## Sripting Extract Subtitle For Video Files                 ##"
echo -e "###############################################################${OFF}"
echo " "

xsatusub() {
        echo "###############################################################"
        for file in $(ls *.mkv)
        do
                [ -f $file ] && ffmpeg -i $file -f webvtt $file.vtt
        done
        echo "###############################################################"
}

xpilihsub() {
        echo "###############################################################"
        for file in $(ls *.mkv)
        do
                [ -f $file ] && ffmpeg -i $file -map 0:s:$1 $file.srt
        done
        echo "###############################################################"
        tanyaempat
}

tanyasatu() {
        echo -e "${On_White} Apakah ingin mengextrak subtitle di folder ini? ${OFF}${BWhite} "
        read -p " Masukan Pilihan: (y/n) " RESP
        if [ "$RESP" = "y" ]; then
          tanyadua
        else
          echo -e "${On_Red} Byee.. ${OFF}\n"
        fi
}

tanyadua() {
        echo -e "${On_White} Ingin mengextrak default/satu Subs saja? ${OFF}${BWhite} "
        read -p " Masukan Pilihan: (y/n) " RESP
        if [ "$RESP" = "y" ]; then
          xsatusub
          echo -e "${OFF}"
        else
          tanyatiga
        fi
}

tanyatiga() {
        echo -e "${On_White} Masukan Stream Subs yang diinginkan? ${OFF}${BWhite} "
        read -p " Masukan Pilihan Stream: " no_stream
          xpilihsub $no_stream
}

tanyaempat() {
        echo -e "${On_White} Masih ingin mengextrak Sub yang lain? ${OFF}${BWhite} "
        read -p " Masukan Pilihan: (y/n) " RESP
        if [ "$RESP" = "y" ]; then
          tanyatiga
        else
          echo -e "${On_Red} Byee.. ${OFF}\n"
        fi
}

tanyasatu
