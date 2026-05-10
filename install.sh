#!/bin/sh
apt update
apt install unrar -y
wget -O ffmpeg.rar "https://www.dropbox.com/scl/fi/rd749ndevev3tiop4o2lx/ffmpeg.rar?rlkey=w2vb7pfp34xgizq0d22aqngyd&dl=1"
unrar x ffmpeg.rar
cd ffmpeg/
mv ffmpeg /usr/local/bin/
mv ffprobe /usr/local/bin/
cd /root
wget https://github.com/sibuk76/o11Pro/raw/main/o11Pro.rar
unrar x o11Pro.rar /home
chmod -R +x /home/o11Pro/
wget https://raw.githubusercontent.com/sibuk76/o11Pro/refs/heads/main/setup-o11-tmpfs.sh
chmod +x /root/setup-o11-tmpfs.sh
sudo /root/setup-o11-tmpfs.sh
wget https://raw.githubusercontent.com/sibuk76/o11Pro/main/o11Pro.service
chmod +x o11Pro.service
mv ./o11Pro.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable o11Pro.service
systemctl start o11Pro.service

echo "Installation Complete"
echo "Please login http://YOURIP:6060"
echo "USERNAME/PASSWORD admin admin"
