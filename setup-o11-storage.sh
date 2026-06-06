#!/bin/bash
# o11Pro depolama yapılandırması
#
# HLS  → DISK (104+ kanal için tmpfs YETERSİZ, birkaç saatte dolar)
# dl   → tmpfs (geçici indirmeler, küçük ve hızlı)

set -euo pipefail

O11_HOME="/home/o11Pro"
DL_TMPFS_SIZE="${DL_TMPFS_SIZE:-10%}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Root olarak çalıştır: sudo $0"
  exit 1
fi

echo "[1/4] Eski HLS tmpfs kaydı kaldırılıyor..."
sed -i '\|/home/o11Pro/hls|d' /etc/fstab
sed -i '\|/home/o11Pro/dl|d' /etc/fstab

echo "[2/4] HLS tmpfs varsa unmount..."
if mountpoint -q "${O11_HOME}/hls" 2>/dev/null; then
  findmnt -t tmpfs "${O11_HOME}/hls" >/dev/null 2>&1 && umount "${O11_HOME}/hls" || true
fi

echo "[3/4] Dizinler oluşturuluyor..."
mkdir -p "${O11_HOME}/hls/live"
mkdir -p "${O11_HOME}/dl"
mkdir -p "${O11_HOME}/scripts"
mkdir -p "${O11_HOME}/logs" "${O11_HOME}/providers" "${O11_HOME}/epg"
mkdir -p "${O11_HOME}/fonts" "${O11_HOME}/logos" "${O11_HOME}/manifests"
mkdir -p "${O11_HOME}/overlay" "${O11_HOME}/offair" "${O11_HOME}/rec"
chmod 755 "${O11_HOME}/hls" "${O11_HOME}/hls/live"

echo "[4/4] fstab güncelleniyor (sadece dl tmpfs)..."
if ! grep -q "/home/o11Pro/dl" /etc/fstab; then
  cat >> /etc/fstab <<EOF

# o11Pro — dl geçici indirmeler (HLS disktedir!)
tmpfs ${O11_HOME}/dl tmpfs rw,noatime,nosuid,nodev,noexec,mode=1777,size=${DL_TMPFS_SIZE} 0 0
EOF
fi

mount -av

echo ""
echo "Depolama hazır:"
echo "  HLS : ${O11_HOME}/hls/live  → $(df -h "${O11_HOME}/hls" | tail -1 | awk '{print $1" ("$2" toplam, "$4" boş)"}')"
echo "  dl  : ${O11_HOME}/dl          → tmpfs ${DL_TMPFS_SIZE}"
