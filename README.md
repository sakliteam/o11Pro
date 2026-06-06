# o11Pro Kurulum Paketi

**Geliştirici:** Sakli Karak ([@sakliteam](https://github.com/sakliteam))

100+ kanallı canlı ortamda test edilmiş, production-ready o11Pro kurulum paketi.

## Neden bu paket?

Canlı ortamda (104 autostart kanal) şu sorunlar tespit edilip giderildi:

| Sorun | Çözüm |
|-------|-------|
| HLS tmpfs birkaç dakikada doluyordu | HLS **diske** taşındı |
| cleanup.py 60 sn'de tüm `.ts` siliyordu | Akıllı playlist-aware cleanup |
| Restart sonrası kanallar 2-5 dk düşüyordu | Depolama + cleanup + systemd fix |
| Disk sınırsız büyüyordu | 20 dk retention + m4s cache temizliği |

## Hızlı Kurulum (yeni sunucu)

```bash
git clone https://github.com/sakliteam/o11Pro.git
cd o11Pro
chmod +x *.sh
sudo ./install.sh
sudo ./verify.sh
```

## Dosyalar

```
├── install.sh              # Ana kurulum
├── setup-o11-storage.sh    # HLS=disk, dl=tmpfs
├── cleanup.py              # Akıllı segment temizliği
├── o11Pro.service          # systemd unit
├── verify.sh               # Sağlık kontrolü
├── uninstall.sh            # Servis kaldırma
├── config/
│   └── provider-tuning.md  # delta.cfg önerileri
└── README.md
```

## Mevcut sunucuya fix uygulama

```bash
sudo bash setup-o11-storage.sh
sudo install -m 755 cleanup.py /home/o11Pro/scripts/cleanup.py
sudo cp o11Pro.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl restart o11Pro.service
sudo ./verify.sh
```

## Ortam değişkenleri

```bash
WEB_PORT=6060 STREAM_PORT=8080 DL_TMPFS_SIZE=10% sudo ./install.sh
```

## Portlar

| Port | Amaç |
|------|------|
| 6060 | Web yönetim arayüzü |
| 8080 | HLS/stream çıkışı |

## Stream URL

```
http://SUNUCU:8080/stream/delta/KANAL_ID?u=admin&p=HASH
http://SUNUCU:8080/stream/delta/22/master.m3u8?u=admin&p=HASH
```

## cleanup.py ayarları

| Sabit | Varsayılan | Açıklama |
|-------|------------|----------|
| TS_RETENTION | 1200 (20 dk) | Eski segment silme |
| MIN_LIVE_KEEP | 30 | Korunan son segment |
| ORPHAN_AGE | 180 (3 dk) | Yetim dosyalar |
| M4S_AGE | 300 (5 dk) | DASH cache |

## Disk gereksinimleri

| Kanal | Tahmini kullanım |
|-------|-----------------|
| ~100 kanal | ~130 GB (stabil) |
| Önerilen boş disk | **200 GB+** |

## Sağlık kontrolü

```bash
sudo ./verify.sh
```

## Cron

Cleanup her dakika — log: `/home/o11Pro/logs/cleanup.log`

## Notlar

- HLS **asla tmpfs'e konmamalı** — 50+ autostart kanalda RAM diski yetersiz kalır
- `setup-o11-tmpfs.sh` kullanımdan kaldırıldı, `setup-o11-storage.sh` kullanın
