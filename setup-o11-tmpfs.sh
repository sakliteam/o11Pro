#!/bin/bash
echo "UYARI: setup-o11-tmpfs.sh kullanımdan kaldırıldı."
echo "HLS artık tmpfs yerine disk kullanıyor. setup-o11-storage.sh çalıştırılıyor..."
DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "${DIR}/setup-o11-storage.sh"
