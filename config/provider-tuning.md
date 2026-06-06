# delta.cfg / Provider Ayar Önerileri

100+ autostart kanal için önerilen provider ayarları.

## Kritik ayarlar

```json
{
    "MaxDownloadConcurrency": 60,
    "RestartDelay": 10,
    "AlwaysAutorestart": true,
    "PlaylistDuration": 15,
    "HlsIsTs": true,
    "SequencialAutostartPeriod": 2
}
```

## Açıklamalar

### SequencialAutostartPeriod: 2
Restart sonrası kanalları 2'şer saniye arayla başlatır.
104 kanal aynı anda değil ~3.5 dakikaya yayılır → CPU/network spike azalır.

### MaxDownloadConcurrency: 60
Varsayılan 40, 100+ kanal için yetersiz. 60-80 arası deneyin.

### Autostart kanalları
404 veren ölü kanallarda autostart kapatın (Fashion TV, SLAM!TV vb.).
Sürekli restart CPU/network israf eder.

## 404 kanal tespiti

```bash
grep -l "404" /home/o11Pro/logs/delta_*.log | sed 's|.*/delta_||;s|.log||'
```

## Depolama

- HLS → disk (`/home/o11Pro/hls/live`)
- dl → tmpfs (geçici)
- cleanup.py → cron her dakika

Bu ayarlar o11Pro web arayüzünden veya `providers/delta.cfg` dosyasından yapılır.
