#!/bin/bash
# App Name: iJoo DNS BlackList (JoBList)
# Author: iJoo (admin@ijoo.org)
# Fungsi: DNS filtering and Blacklist Website tertentu..
# Cara menggunakannya tinggal di download dan di "eksekusi" dalam shell
# root@~# bash JoBList.sh
# 
# setelah selesai bisa menambahkan domain yang akan diblacklist dengan perintah "ipk"
# dibuat dengan Debian 12, tapi kemungkinan akan jalan di Ubuntu 20+
# 

if [[ $(id -u) != 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

install_update() {
  echo " [!] Updating System >>>>"
  rm -rf /etc/apt/sources.list
  wget https://raw.githubusercontent.com/ijoo/ijooscript/main/sources.list -O /etc/apt/sources.list
  timedatectl set-timezone Asia/Jakarta 
  apt update
  apt upgrade -y
  echo " [!] Update Selesai <<<<"
}

install_mulai() {
  echo " [!] Instalasi >>>>"
  apt install -y build-essential wget nano
  apt install -y bind9 bind9-dev net-tools bind9-utils ntp
  echo " [!] Install Selesai <<<<"
}

install_setup() {
  local_ips=$(hostname -I)
  echo " [!] Config System >>>> "
  mkdir -p /etc/bind/block
  cp /etc/bind/db.0 /etc/bind/block/db.block
  install_block
  touch /etc/bind/named.conf.block-zones
  chown root:bind /etc/bind/block /etc/bind/block/db.block /etc/bind/named.conf.block-zones
  echo "include \"/etc/bind/named.conf.block-zones\";" >> /etc/bind/named.conf
  wget dl.ijoo.org/tools/ipk -O /usr/local/bin/ipk
  chmod 755 /usr/local/bin/ipk
  install_named
  systemctl restart named
}

install_block() {
local_ips=$(hostname -I)
echo "@ IN A $local_ips" >> /etc/bind/block/db.block
echo "* IN CNAME @" >> /etc/bind/block/db.block
}

install_named() {
cat > /etc/bind/named.conf.options << EOF
options {
        directory "/var/cache/bind";
        recursion yes;
        allow-transfer { none; };
        dnssec-validation auto;
        auth-nxdomain no;
        listen-on-v6 { any; };
        check-names master ignore;
        check-names slave ignore;
        allow-query { any; };

};
EOF
}

# Main script
echo "############################################################"
echo " "
echo -n " [!] Apakah ingin iJoo DNS-BlackList (JoBList)? [y/n] "
read -r inul

case "$inul" in
        y|Y)
                echo " [!] Menginstall dimulai!!"
                install_update
                install_mulai
                install_setup
        ;;
        n|N)
            echo " [!] Tidak Jadi Install"
        ;;
        *)
                echo "Silakan Memilih Y/N"
        ;;
esac
