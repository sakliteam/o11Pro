#!/bin/bash
# o11Pro kurulum sağlık kontrolü

set -uo pipefail

O11_HOME="/home/o11Pro"
ERR=0

ok()   { echo "  [OK]  $1"; }
warn() { echo "  [!!]  $1"; ERR=1; }
fail() { echo "  [XX]  $1"; ERR=1; }

echo "=== o11Pro Sağlık Kontrolü ==="

# Servis
if systemctl is-active --quiet o11Pro.service; then
  ok "o11Pro.service çalışıyor"
else
  fail "o11Pro.service çalışmıyor"
fi

# Binary
if [[ -x "${O11_HOME}/o11Pro" ]]; then
  ok "o11Pro binary mevcut"
else
  fail "o11Pro binary bulunamadı"
fi

# FFmpeg
if [[ -x /usr/local/bin/ffmpeg ]]; then
  ok "ffmpeg mevcut"
else
  fail "ffmpeg bulunamadı"
fi

# HLS disktemi?
if findmnt -t tmpfs "${O11_HOME}/hls" >/dev/null 2>&1; then
  fail "HLS hâlâ tmpfs üzerinde — 100+ kanalda disk dolacak! setup-o11-storage.sh çalıştır"
else
  ok "HLS disk üzerinde ($(df -h ${O11_HOME}/hls | tail -1 | awk '{print $1}'))"
fi

# dl tmpfs
if mountpoint -q "${O11_HOME}/dl" 2>/dev/null; then
  ok "dl tmpfs mount OK"
else
  warn "dl tmpfs mount yok (kritik değil)"
fi

# Cleanup script
if [[ -f "${O11_HOME}/scripts/cleanup.py" ]]; then
  ok "cleanup.py kurulu"
  if grep -q "AGE_LIMIT = 60" "${O11_HOME}/scripts/cleanup.py" 2>/dev/null; then
    fail "ESKİ cleanup.py tespit edildi (60sn .ts silme — kanalları düşürür!)"
  else
    ok "cleanup.py güncel (akıllı temizlik)"
  fi
else
  fail "cleanup.py bulunamadı"
fi

# Cron
if crontab -l 2>/dev/null | grep -q "cleanup.py"; then
  ok "cleanup cron aktif"
else
  warn "cleanup cron kayıtlı değil"
fi

# Portlar
if ss -tlnp 2>/dev/null | grep -q ":6060"; then
  ok "Web port 6060 dinleniyor"
else
  warn "Web port 6060 dinlenmiyor"
fi
if ss -tlnp 2>/dev/null | grep -q ":8080"; then
  ok "Stream port 8080 dinleniyor"
else
  warn "Stream port 8080 dinlenmiyor"
fi

# Disk alanı
AVAIL=$(df -BG "${O11_HOME}/hls" | tail -1 | awk '{print $4}' | tr -d G)
if [[ "${AVAIL}" -lt 50 ]] 2>/dev/null; then
  warn "Disk alanı düşük: ${AVAIL}GB boş (100+ kanal için 100GB+ önerilir)"
else
  ok "Disk alanı yeterli: ${AVAIL}GB boş"
fi

# Çalışan kanallar
M3U=$(find "${O11_HOME}/hls/live" -name "stream_0.m3u8" -size +50c 2>/dev/null | wc -l)
if [[ "${M3U}" -gt 0 ]]; then
  ok "${M3U} kanal HLS playlist aktif"
else
  warn "Henüz aktif HLS kanalı yok (autostart bekleniyor olabilir)"
fi

echo "================================"
if [[ "${ERR}" -eq 0 ]]; then
  echo "Sonuç: Tüm kritik kontroller geçti"
else
  echo "Sonuç: Sorunlar var — yukarıdaki [XX]/[!!] satırlarına bak"
fi
exit "${ERR}"
