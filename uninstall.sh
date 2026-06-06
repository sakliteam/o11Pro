#!/bin/bash
# o11Pro kaldırma (veri dizinini silmez)

set -euo pipefail

O11_HOME="/home/o11Pro"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Root olarak çalıştır: sudo $0"
  exit 1
fi

read -rp "o11Pro servisi durdurulup kaldırılacak. Devam? [y/N] " ans
[[ "${ans}" =~ ^[yY]$ ]] || exit 0

systemctl stop o11Pro.service 2>/dev/null || true
systemctl disable o11Pro.service 2>/dev/null || true
rm -f /etc/systemd/system/o11Pro.service
systemctl daemon-reload

crontab -l 2>/dev/null | grep -v "${O11_HOME}/scripts/cleanup.py" | crontab - 2>/dev/null || true

sed -i '\|/home/o11Pro/hls|d' /etc/fstab
sed -i '\|/home/o11Pro/dl|d' /etc/fstab
umount "${O11_HOME}/dl" 2>/dev/null || true

echo "Servis kaldırıldı. ${O11_HOME} veri dizini korundu."
