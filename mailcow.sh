#!/usr/bin/env bash
# =============================================================================
#  mailcow.sh — Setup Mailcow otomatis
#  Alur: email masuk ke Mailcow (disimpan + filter spam) -> diteruskan ke Gmail,
#        kirim lewat SMTP Mailcow (587/465), balas lewat webmail SOGo bila perlu.
#
#  Jalankan sebagai root di VPS Ubuntu 22.04/24.04 atau Debian 12 yang bersih:
#      sudo bash mailcow.sh
#
#  Log: /var/log/mailcow-setup.log
#  Ringkasan: /root/mailcow-setup-summary.txt
# =============================================================================
set -Eeuo pipefail

MAILCOW_DIR="/opt/mailcow-dockerized"
LOG_FILE="/var/log/mailcow-setup.log"
SUMMARY_FILE="/root/mailcow-setup-summary.txt"

# ---------- tampilan ----------
C_R=$'\e[31m'; C_G=$'\e[32m'; C_Y=$'\e[33m'; C_B=$'\e[36m'; C_0=$'\e[0m'
step() { echo; echo "${C_B}==> $*${C_0}"; }
ok()   { echo "${C_G}  [OK]${C_0} $*"; }
warn() { echo "${C_Y}  [PERINGATAN]${C_0} $*"; }
die()  { echo "${C_R}  [GAGAL]${C_0} $*" >&2; exit 1; }
trap 'echo "${C_R}Script berhenti di baris $LINENO. Cek log: $LOG_FILE${C_0}" >&2' ERR

ask() { # ask VAR "Pertanyaan" "default"
  local __var=$1 __q=$2 __def=${3:-} __ans
  if [[ -n $__def ]]; then read -r -p "$__q [$__def]: " __ans; __ans=${__ans:-$__def}
  else read -r -p "$__q: " __ans; fi
  printf -v "$__var" '%s' "$__ans"
}
ask_yn() { # ask_yn VAR "Pertanyaan" y|n
  local __var=$1 __q=$2 __def=$3 __ans __hint
  [[ $__def == y ]] && __hint="Y/n" || __hint="y/N"
  while true; do
    read -r -p "$__q [$__hint]: " __ans; __ans=${__ans:-$__def}
    case ${__ans,,} in y|ya|yes) printf -v "$__var" y; return;; n|no|tidak) printf -v "$__var" n; return;; esac
  done
}
ask_secret() { # ask_secret VAR "Pertanyaan" minlen
  local __var=$1 __q=$2 __min=$3 __a __b
  while true; do
    read -r -s -p "$__q (min. $__min karakter): " __a; echo
    read -r -s -p "Ulangi: " __b; echo
    if [[ $__a != "$__b" ]]; then echo "  Tidak sama, ulangi."; continue; fi
    if (( ${#__a} < __min )); then echo "  Terlalu pendek."; continue; fi
    printf -v "$__var" '%s' "$__a"; return
  done
}
confirm_or_exit() { local a; ask_yn a "$1 Tetap lanjut?" n; [[ $a == y ]] || die "Dibatalkan."; }
is_email() { [[ $1 =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; }

set_conf() { # set_conf KEY VALUE  -> mengganti/menambah KEY=VALUE di mailcow.conf
  local key=$1 val=$2 f="$MAILCOW_DIR/mailcow.conf"
  if grep -qE "^#?${key}=" "$f"; then
    sed -i -E "s|^#?${key}=.*|${key}=${val}|" "$f"
  else
    echo "${key}=${val}" >> "$f"
  fi
}

# ---------- API Mailcow ----------
api() { # api METHOD PATH [JSON]
  local method=$1 path=$2 body=${3:-}
  local args=(-sk --max-time 60 --resolve "${MAILCOW_HOSTNAME}:443:${IPV4}"
              -H "X-API-Key: ${API_KEY}" -H "Content-Type: application/json" -X "$method")
  [[ -n $body ]] && args+=(--data "$body")
  curl "${args[@]}" "https://${MAILCOW_HOSTNAME}/api/v1/${path}"
}
api_ok() { # api_ok "Deskripsi" METHOD PATH JSON  -> laporkan sukses/gagal dari respons
  local desc=$1 resp
  resp=$(api "$2" "$3" "${4:-}") || { warn "$desc: tidak ada respons dari API"; return 1; }
  if echo "$resp" | jq -e 'if type=="array" then any(.[]; .type=="danger" or .type=="error") else (.type=="danger" or .type=="error") end' >/dev/null 2>&1; then
    warn "$desc: $(echo "$resp" | jq -c '[.. | .msg? // empty]' 2>/dev/null || echo "$resp")"
    return 1
  fi
  ok "$desc"
}

# =============================================================================
# 0. Pemeriksaan awal
# =============================================================================
[[ $EUID -eq 0 ]] || die "Jalankan sebagai root: sudo bash $0"
. /etc/os-release 2>/dev/null || die "Tidak bisa membaca /etc/os-release"
[[ $ID == ubuntu || $ID == debian ]] || warn "OS $PRETTY_NAME belum diuji (disarankan Ubuntu/Debian)."
command -v apt-get >/dev/null || die "Script ini butuh apt-get (Ubuntu/Debian)."

cat <<'EOF'

 ============================================================
  Setup Mailcow — terima di Gmail, kirim lewat SMTP
 ============================================================
  Tekan Enter untuk memakai nilai default di dalam [kurung].
EOF

CONFIG_ONLY=n
if [[ -f $MAILCOW_DIR/mailcow.conf ]]; then
  ask_yn CONFIG_ONLY "Mailcow sudah terpasang di $MAILCOW_DIR. Lewati instalasi, hanya jalankan konfigurasi?" y
  [[ $CONFIG_ONLY == y ]] || die "Hapus/rename $MAILCOW_DIR dulu kalau ingin instal ulang."
fi

# =============================================================================
# 1. Input dari user
# =============================================================================
step "1. Data server dan domain"
while true; do
  ask MAILCOW_HOSTNAME "Hostname mail server (FQDN)" "mail.ijoo.org"
  [[ $MAILCOW_HOSTNAME =~ ^[a-z0-9-]+(\.[a-z0-9-]+)+$ ]] && [[ $MAILCOW_HOSTNAME == *.*.* ]] && break
  echo "  Harus berupa subdomain, contoh: mail.domainanda.com"
done
ask MAIL_DOMAIN "Domain email (alamat jadi nama@domain ini)" "${MAILCOW_HOSTNAME#*.}"

DETECTED_V4=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1 || true)
ask IPV4 "IPv4 publik server" "${DETECTED_V4:-194.102.181.37}"
[[ $IPV4 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || die "IPv4 tidak valid: $IPV4"

ask IPV6 "IPv6 yang dipakai untuk email (kosongkan = tanpa IPv6)" "2a0e:1d80:15:adf7::5afe:c0de"
IPV6=${IPV6,,}
if [[ $IPV6 == "-" || $IPV6 == "none" ]]; then IPV6=""; fi
IPV6_PTR_OK=n; BIND_SPECIFIC=n
if [[ -n $IPV6 ]]; then
  [[ $IPV6 == *:* ]] || die "IPv6 tidak valid: $IPV6"
  ask_yn IPV6_PTR_OK "Apakah PTR/rDNS IPv6 $IPV6 SUDAH diset ke $MAILCOW_HOSTNAME?" n
  ask_yn BIND_SPECIFIC "Ikat Mailcow HANYA ke $IPV4 dan $IPV6 (abaikan IP lain di VPS)?" y
fi

ask TZ_NAME "Timezone" "Asia/Jakarta"

step "2. Akun email"
ask LOCAL_PART "Nama mailbox (bagian sebelum @)" "info"
MAILBOX="${LOCAL_PART}@${MAIL_DOMAIN}"
is_email "$MAILBOX" || die "Alamat tidak valid: $MAILBOX"
ask_secret MAILBOX_PASS "Password untuk $MAILBOX (login SMTP & webmail)" 12

while true; do
  ask FORWARD_TO "Alamat Gmail tujuan forward" ""
  is_email "$FORWARD_TO" && break
  echo "  Alamat email tidak valid."
done
ask_yn BCC_ENABLE "Salin otomatis email yang ANDA KIRIM dari $MAILBOX ke $FORWARD_TO (BCC)?" y
while true; do
  ask RETENTION_DAYS "Hapus salinan di server setelah berapa hari? (0 = jangan hapus)" "180"
  [[ $RETENTION_DAYS =~ ^[0-9]+$ ]] && break
done

step "3. Admin Mailcow"
ask_secret ADMIN_PASS "Password BARU untuk admin panel (user: admin)" 12

RAM_MB=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
if (( RAM_MB < 7000 )); then
  ask_yn SKIP_CLAMD "RAM ${RAM_MB} MB. Matikan antivirus ClamAV agar hemat RAM?" y
else
  ask_yn SKIP_CLAMD "Matikan antivirus ClamAV?" n
fi
ask_yn REMOVE_API_KEY "Hapus API key sementara setelah setup selesai (disarankan)?" y

cat <<EOF

 ------------------------------------------------------------
  Hostname     : $MAILCOW_HOSTNAME
  Domain email : $MAIL_DOMAIN
  IPv4         : $IPV4
  IPv6         : ${IPV6:-(tidak dipakai)}  PTR siap: $IPV6_PTR_OK  Bind khusus: $BIND_SPECIFIC
  Mailbox      : $MAILBOX
  Forward ke   : $FORWARD_TO   (BCC kiriman: $BCC_ENABLE)
  Auto-hapus   : ${RETENTION_DAYS} hari (0 = tidak)
  Timezone     : $TZ_NAME     ClamAV mati: $SKIP_CLAMD
 ------------------------------------------------------------
EOF
ask_yn GO "Mulai instalasi?" y
[[ $GO == y ]] || die "Dibatalkan."

# Mulai mencatat log (password tidak pernah ditulis ke log)
touch "$LOG_FILE"; chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== mailcow.sh mulai $(date -Is) ==="

# =============================================================================
# 4. Paket dasar & pengecekan jaringan/DNS
# =============================================================================
step "4. Install paket dasar"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq git openssl curl gawk coreutils grep jq dnsutils netcat-openbsd \
  ca-certificates iproute2 cron >/dev/null
ok "Paket dasar terpasang"

step "5. Cek IP, port 25, dan DNS"
ip -4 -o addr show | grep -qw "$IPV4" && ok "IPv4 $IPV4 ada di server" \
  || confirm_or_exit "IPv4 $IPV4 tidak ditemukan di interface server (wajar kalau VPS memakai NAT)."
if [[ -n $IPV6 ]]; then
  ip -6 -o addr show | grep -qi "$IPV6/" && ok "IPv6 $IPV6 ada di server" \
    || confirm_or_exit "IPv6 $IPV6 tidak ditemukan di interface server."
fi

if nc -4 -vz -w 10 gmail-smtp-in.l.google.com 25 >/dev/null 2>&1; then
  ok "Port 25 keluar terbuka"
else
  confirm_or_exit "Port 25 keluar TERBLOKIR. Email tidak akan terkirim sampai provider membukanya."
fi

for p in 25 80 443 587 993; do
  if ss -tlnH "sport = :$p" | grep -q . && ! docker ps 2>/dev/null | grep -q mailcow; then
    confirm_or_exit "Port $p sudah dipakai program lain ($(ss -tlnpH "sport = :$p" | awk '{print $NF}' | head -1))."
  fi
done

A_REC=$(dig +short A "$MAILCOW_HOSTNAME" @1.1.1.1 | tail -1)
[[ $A_REC == "$IPV4" ]] && ok "A $MAILCOW_HOSTNAME -> $IPV4" \
  || confirm_or_exit "A record $MAILCOW_HOSTNAME = '${A_REC:-kosong}', seharusnya $IPV4. SSL otomatis akan gagal (pastikan DNS only di Cloudflare)."
PTR4=$(dig +short -x "$IPV4" @1.1.1.1 | sed 's/\.$//' | head -1)
[[ $PTR4 == "$MAILCOW_HOSTNAME" ]] && ok "PTR $IPV4 -> $PTR4" \
  || confirm_or_exit "PTR $IPV4 = '${PTR4:-kosong}', seharusnya $MAILCOW_HOSTNAME. Set di panel VPS."
if [[ -n $IPV6 && $IPV6_PTR_OK == y ]]; then
  PTR6=$(dig +short -x "$IPV6" @1.1.1.1 | sed 's/\.$//' | head -1)
  if [[ $PTR6 == "$MAILCOW_HOSTNAME" ]]; then ok "PTR $IPV6 -> $PTR6"
  else
    warn "PTR IPv6 = '${PTR6:-kosong}'. Pengiriman dipaksa lewat IPv4 agar aman."
    IPV6_PTR_OK=n
  fi
fi

# =============================================================================
# 5. Sistem: hostname, timezone, swap
# =============================================================================
step "6. Hostname, timezone, swap"
hostnamectl set-hostname "$MAILCOW_HOSTNAME"
grep -q "$MAILCOW_HOSTNAME" /etc/hosts || echo "$IPV4 $MAILCOW_HOSTNAME ${MAILCOW_HOSTNAME%%.*}" >> /etc/hosts
timedatectl set-timezone "$TZ_NAME" 2>/dev/null || warn "Timezone $TZ_NAME tidak dikenali, dilewati."
if ! swapon --show | grep -q .; then
  fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  ok "Swap 2 GB dibuat"
else
  ok "Swap sudah ada"
fi

# =============================================================================
# 6. Docker
# =============================================================================
step "7. Docker"
if ! command -v docker >/dev/null; then
  curl -fsSL https://get.docker.com | CHANNEL=stable sh
fi
systemctl enable --now docker >/dev/null
docker compose version >/dev/null 2>&1 || apt-get install -y -qq docker-compose-plugin >/dev/null
ok "$(docker --version) | $(docker compose version --short 2>/dev/null)"

# =============================================================================
# 7. Download & konfigurasi Mailcow
# =============================================================================
step "8. Download & generate config Mailcow"
API_KEY=$(openssl rand -hex 24)
cd /opt
if [[ $CONFIG_ONLY == n ]]; then
  [[ -d $MAILCOW_DIR ]] || git clone -q https://github.com/mailcow/mailcow-dockerized "$MAILCOW_DIR"
  cd "$MAILCOW_DIR"
  umask 0022
  MAILCOW_HOSTNAME="$MAILCOW_HOSTNAME" MAILCOW_TZ="$TZ_NAME" MAILCOW_BRANCH=master \
    SKIP_CLAMD="$SKIP_CLAMD" FORCE=y ./generate_config.sh
  ok "mailcow.conf dibuat"
fi
cd "$MAILCOW_DIR"
cp mailcow.conf "mailcow.conf.bak.$(date +%s)"

# --- IP keluar (SNAT) ---
set_conf SNAT_TO_SOURCE "$IPV4"
if [[ -n $IPV6 ]]; then set_conf SNAT6_TO_SOURCE "$IPV6"; fi

# --- API key sementara (hanya bisa dipakai dari server ini) ---
NET4=$(grep -E '^IPV4_NETWORK=' mailcow.conf | cut -d= -f2); NET4=${NET4:-172.22.1}
ALLOW="127.0.0.1,::1,${NET4}.1,${IPV4}"
[[ -n $IPV6 ]] && ALLOW+=",${IPV6}"
set_conf API_KEY "$API_KEY"
set_conf API_ALLOW_FROM "$ALLOW"

# --- Bind hanya ke IP tertentu ---
if [[ $BIND_SPECIFIC == y ]]; then
  set_conf HTTP_BIND "$IPV4";  set_conf HTTPS_BIND "$IPV4"
  set_conf SMTP_PORT "$IPV4:25"; set_conf SMTPS_PORT "$IPV4:465"; set_conf SUBMISSION_PORT "$IPV4:587"
  set_conf IMAP_PORT "$IPV4:143"; set_conf IMAPS_PORT "$IPV4:993"
  set_conf POP_PORT "$IPV4:110";  set_conf POPS_PORT "$IPV4:995"; set_conf SIEVE_PORT "$IPV4:4190"
  [[ -f docker-compose.override.yml ]] && cp docker-compose.override.yml "docker-compose.override.yml.bak.$(date +%s)"
  cat > docker-compose.override.yml <<EOF
# Dibuat oleh mailcow.sh: bind IPv6 hanya ke $IPV6
services:
  dovecot-mailcow:
    ports:
      - '[$IPV6]:143:143'
      - '[$IPV6]:993:993'
      - '[$IPV6]:110:110'
      - '[$IPV6]:995:995'
      - '[$IPV6]:4190:4190'
  postfix-mailcow:
    ports:
      - '[$IPV6]:25:25'
      - '[$IPV6]:465:465'
      - '[$IPV6]:587:587'
  nginx-mailcow:
    ports:
      - '[$IPV6]:80:80'
      - '[$IPV6]:443:443'
EOF
  ok "Bind ke $IPV4 dan [$IPV6]"
fi

# --- Paksa kirim lewat IPv4 bila PTR IPv6 belum siap ---
EXTRA_CF=data/conf/postfix/extra.cf
touch "$EXTRA_CF"
sed -i '/^smtp_address_preference/d' "$EXTRA_CF"
if [[ $IPV6_PTR_OK != y ]]; then
  echo "smtp_address_preference = ipv4" >> "$EXTRA_CF"
  ok "Postfix mengutamakan IPv4 untuk kirim"
fi

# =============================================================================
# 8. Jalankan Mailcow
# =============================================================================
step "9. Download image & jalankan Mailcow (bisa 5-15 menit)"
docker compose pull -q
docker compose down >/dev/null 2>&1 || true
docker compose up -d
ok "Container berjalan"

step "10. Menunggu API Mailcow siap"
for i in $(seq 1 60); do
  if api GET status/version 2>/dev/null | jq -e '.version' >/dev/null 2>&1; then ok "API siap"; break; fi
  (( i == 60 )) && die "API tidak merespons setelah 10 menit. Cek: docker compose logs --tail=100 php-fpm-mailcow nginx-mailcow"
  sleep 10
done

# =============================================================================
# 9. Konfigurasi lewat API
# =============================================================================
step "11. Konfigurasi admin, domain, mailbox, DKIM"
api_ok "Password admin diganti" POST edit/admin "$(jq -n --arg p "$ADMIN_PASS" \
  '{items:["admin"], attr:{username_new:"admin", active:"1", password:$p, password2:$p}}')" \
  || warn "Ganti password admin manual di https://$MAILCOW_HOSTNAME/admin (default: admin / moohoo)!"

api_ok "Domain $MAIL_DOMAIN ditambahkan" POST add/domain "$(jq -n --arg d "$MAIL_DOMAIN" \
  '{domain:$d, description:$d, aliases:"400", mailboxes:"10", defquota:"3072", maxquota:"10240",
    quota:"20480", active:"1", restart_sogo:"1", dkim_selector:"dkim", key_size:"2048"}')" || true

api_ok "Mailbox $MAILBOX dibuat" POST add/mailbox "$(jq -n --arg l "$LOCAL_PART" --arg d "$MAIL_DOMAIN" --arg p "$MAILBOX_PASS" \
  '{local_part:$l, domain:$d, name:$l, password:$p, password2:$p, quota:"3072", active:"1", force_pw_update:"0"}')" || true

DKIM_PUB=$(api GET "get/dkim/$MAIL_DOMAIN" 2>/dev/null | jq -r '.pubkey // empty' 2>/dev/null || true)
if [[ -z $DKIM_PUB ]]; then
  api_ok "DKIM 2048-bit dibuat" POST add/dkim "$(jq -n --arg d "$MAIL_DOMAIN" '{domains:$d, dkim_selector:"dkim", key_size:"2048"}')" || true
  DKIM_PUB=$(api GET "get/dkim/$MAIL_DOMAIN" 2>/dev/null | jq -r '.pubkey // empty' 2>/dev/null || true)
fi
[[ -n $DKIM_PUB ]] && ok "DKIM tersedia" || warn "DKIM belum terbaca; ambil manual di admin panel."

step "12. Forward ke Gmail (dengan salinan) & BCC"
SIEVE=$(cat <<EOF
require ["copy", "fileinto"];

# Spam tidak diteruskan, cukup disimpan di Junk
if header :contains "X-Spam-Flag" "YES" {
  fileinto "Junk";
  stop;
}

redirect :copy "$FORWARD_TO";
EOF
)
api_ok "Filter forward ke $FORWARD_TO" POST add/filter "$(jq -n --arg u "$MAILBOX" --arg s "$SIEVE" \
  '{username:$u, filter_type:"prefilter", script_desc:"Forward ke Gmail (dibuat mailcow.sh)", script_data:$s, active:"1"}')" || true

if [[ $BCC_ENABLE == y ]]; then
  api_ok "BCC kiriman $MAILBOX -> $FORWARD_TO" POST add/bcc "$(jq -n --arg l "$MAILBOX" --arg b "$FORWARD_TO" \
    '{local_dest:$l, bcc_dest:$b, type:"sender", active:"1"}')" || true
fi

# =============================================================================
# 10. Auto-hapus salinan lama
# =============================================================================
if (( RETENTION_DAYS > 0 )); then
  step "13. Auto-hapus salinan lebih tua dari $RETENTION_DAYS hari"
  cat > /etc/cron.d/mailcow-expunge <<EOF
# Dibuat oleh mailcow.sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 3 * * * root cd $MAILCOW_DIR && docker compose exec -T dovecot-mailcow doveadm expunge -u $MAILBOX mailbox '*' savedbefore ${RETENTION_DAYS}d >/dev/null 2>&1
EOF
  chmod 644 /etc/cron.d/mailcow-expunge
  ok "Cron harian jam 03:00 terpasang (/etc/cron.d/mailcow-expunge)"
fi

# =============================================================================
# 11. Hapus API key sementara
# =============================================================================
if [[ $REMOVE_API_KEY == y ]]; then
  step "14. Menghapus API key sementara"
  sed -i -E 's|^API_KEY=.*|#API_KEY=|' mailcow.conf
  docker compose up -d >/dev/null 2>&1
  ok "API key dinonaktifkan"
fi

# =============================================================================
# 12. Ringkasan & DNS yang harus dipasang
# =============================================================================
DKIM_TXT="v=DKIM1;k=rsa;t=s;s=email;p=${DKIM_PUB:-AMBIL_DARI_ADMIN_PANEL}"
AAAA_LINE=""; SPF="v=spf1 mx a:${MAILCOW_HOSTNAME} -all"
if [[ -n $IPV6 && $IPV6_PTR_OK == y ]]; then
  AAAA_LINE="AAAA   ${MAILCOW_HOSTNAME%%.*}               $IPV6   (DNS only)"
fi

{
cat <<EOF
================================================================
 RINGKASAN SETUP MAILCOW — $(date '+%Y-%m-%d %H:%M')
================================================================
Admin panel : https://$MAILCOW_HOSTNAME/admin   (user: admin)
Webmail     : https://$MAILCOW_HOSTNAME/SOGo     (login: $MAILBOX)

Pengaturan SMTP / aplikasi email:
  Server  : $MAILCOW_HOSTNAME
  SMTP    : 587 (STARTTLS) atau 465 (SSL/TLS)
  IMAP    : 993 (SSL/TLS)
  User    : $MAILBOX
  Password: (yang Anda isi tadi)

Email masuk ke $MAILBOX diteruskan ke $FORWARD_TO (salinan disimpan).

---------------- DNS DI CLOUDFLARE (semua DNS only / abu-abu) ----------------
A      ${MAILCOW_HOSTNAME%%.*}               $IPV4   (DNS only)
${AAAA_LINE}
MX     @                  ${MAILCOW_HOSTNAME}   priority 10
TXT    @                  ${SPF}
TXT    dkim._domainkey    ${DKIM_TXT}
TXT    _dmarc             v=DMARC1; p=none; rua=mailto:${MAILBOX}
CNAME  autodiscover       ${MAILCOW_HOSTNAME}   (DNS only)
CNAME  autoconfig         ${MAILCOW_HOSTNAME}   (DNS only)

Hapus MX lain (mis. route*.mx.cloudflare.net) dan matikan Cloudflare Email Routing.
Hanya boleh ada SATU record TXT yang diawali v=spf1.

---------------- PTR / rDNS (di panel provider VPS) ----------------
$IPV4  ->  $MAILCOW_HOSTNAME
EOF
if [[ -n $IPV6 ]]; then
  if [[ $IPV6_PTR_OK == y ]]; then echo "$IPV6  ->  $MAILCOW_HOSTNAME"
  else echo "$IPV6  ->  (belum) — kirim dipaksa IPv4, JANGAN buat AAAA dulu"; fi
fi
cat <<EOF

---------------- LANGKAH BERIKUTNYA ----------------
1. Pasang DNS di atas, tunggu 5-30 menit.
2. Admin panel -> Email -> Configuration -> Domains -> ikon DNS: semua harus hijau.
3. Kirim email ke alamat dari https://www.mail-tester.com (target >= 9/10).
4. Kirim dari email lain ke $MAILBOX -> harus muncul di Gmail.
5. Cek open relay: https://mxtoolbox.com/diagnostic.aspx
6. Update rutin: cd $MAILCOW_DIR && ./update.sh
7. Backup: MAILCOW_BACKUP_LOCATION=/opt/backup $MAILCOW_DIR/helper-scripts/backup_and_restore.sh backup all
================================================================
EOF
} | tee "$SUMMARY_FILE"
chmod 600 "$SUMMARY_FILE"

echo
ok "Selesai. Ringkasan disimpan di $SUMMARY_FILE"
