#!/bin/bash
# o11Pro tam kurulum — disk HLS + akıllı cleanup
# Sakli Karak — https://github.com/sakliteam/o11Pro

set -euo pipefail

O11_HOME="/home/o11Pro"
INSTALLER_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_PORT="${WEB_PORT:-6060}"
STREAM_PORT="${STREAM_PORT:-8080}"
DL_TMPFS_SIZE="${DL_TMPFS_SIZE:-10%}"

O11_RAR_URL="${O11_RAR_URL:-https://github.com/sakliteam/o11Pro/raw/main/o11Pro.rar}"
FFMPEG_RAR_URL="${FFMPEG_RAR_URL:-https://www.dropbox.com/scl/fi/rd749ndevev3tiop4o2lx/ffmpeg.rar?rlkey=w2vb7pfp34xgizq0d22aqngyd&dl=1}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Root olarak çalıştır: sudo $0"
  exit 1
fi

echo "============================================"
echo " o11Pro Kurulum (disk HLS + akıllı cleanup)"
echo "============================================"

echo "[1/9] Paketler..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y unrar wget python3 curl

echo "[2/9] FFmpeg..."
if [[ ! -x /usr/local/bin/ffmpeg ]]; then
  tmpdir=$(mktemp -d)
  wget -q -O "${tmpdir}/ffmpeg.rar" "${FFMPEG_RAR_URL}"
  unrar x -o+ "${tmpdir}/ffmpeg.rar" "${tmpdir}/"
  install -m 755 "${tmpdir}/ffmpeg/ffmpeg" /usr/local/bin/ffmpeg
  rm -rf "${tmpdir}"
  echo "  FFmpeg kuruldu: $(/usr/local/bin/ffmpeg -version | head -1)"
else
  echo "  FFmpeg zaten mevcut, atlanıyor."
fi

echo "[3/9] o11Pro binary..."
if [[ ! -x "${O11_HOME}/o11Pro" ]]; then
  tmpdir=$(mktemp -d)
  wget -q -O "${tmpdir}/o11Pro.rar" "${O11_RAR_URL}"
  unrar x -o+ "${tmpdir}/o11Pro.rar" /home/
  rm -rf "${tmpdir}"
fi
chmod +x "${O11_HOME}/o11Pro" 2>/dev/null || true

echo "[4/9] Dizin yapısı..."
mkdir -p "${O11_HOME}/"{hls/live,dl,scripts,logs,providers,epg,fonts,logos,manifests,overlay,offair,rec}

echo "[5/9] Depolama (HLS=disk, dl=tmpfs)..."
DL_TMPFS_SIZE="${DL_TMPFS_SIZE}" bash "${INSTALLER_DIR}/setup-o11-storage.sh"

echo "[6/9] cleanup.py + cron..."
install -m 755 "${INSTALLER_DIR}/cleanup.py" "${O11_HOME}/scripts/cleanup.py"
CRON_LINE="* * * * * /usr/bin/python3 ${O11_HOME}/scripts/cleanup.py >> ${O11_HOME}/logs/cleanup.log 2>&1"
(crontab -l 2>/dev/null | grep -v "${O11_HOME}/scripts/cleanup.py" || true; echo "${CRON_LINE}") | crontab -

echo "[7/9] systemd servisi..."
# Portları sed ile güncelle
sed "s/-p 6060/-p ${WEB_PORT}/; s/-streamport 8080/-streamport ${STREAM_PORT}/" \
  "${INSTALLER_DIR}/o11Pro.service" > /etc/systemd/system/o11Pro.service
systemctl daemon-reload
systemctl enable o11Pro.service

echo "[8/9] Servis başlatılıyor..."
systemctl restart o11Pro.service
sleep 3

echo "[9/9] Doğrulama..."
bash "${INSTALLER_DIR}/verify.sh" || true

echo ""
echo "============================================"
echo " Kurulum tamamlandı!"
echo "============================================"
echo " Web UI  : http://$(hostname -I | awk '{print $1}'):${WEB_PORT}"
echo " Stream  : http://$(hostname -I | awk '{print $1}'):${STREAM_PORT}"
echo " Kullanıcı: admin / admin  (ilk girişte değiştir)"
echo ""
echo " HLS depolama : DISK ($(df -h ${O11_HOME}/hls | tail -1 | awk '{print $4}') boş)"
echo " Cleanup cron : her dakika (log: ${O11_HOME}/logs/cleanup.log)"
echo "============================================"
