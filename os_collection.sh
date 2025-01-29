#!/bin/bash

LOGFILE="/tmp/server_comparison_$(hostname)_$(date +%Y%m%d_%H%M%S).log"

echo "=== SYSTEM INFO ===" | tee -a $LOGFILE
hostname | tee -a $LOGFILE
uptime | tee -a $LOGFILE
uname -r | tee -a $LOGFILE
cat /etc/redhat-release | tee -a $LOGFILE
df -h | tee -a $LOGFILE

echo -e "\n=== MEMORY USAGE ===" | tee -a $LOGFILE
free -m | tee -a $LOGFILE

echo -e "\n=== CPU USAGE ===" | tee -a $LOGFILE
top -b -n1 | head -20 | tee -a $LOGFILE
lscpu | tee -a $LOGFILE

echo -e "\n=== DISK USAGE ===" | tee -a $LOGFILE
lsblk | tee -a $LOGFILE
df -ih | tee -a $LOGFILE
iostat -dx 1 3 | tee -a $LOGFILE

echo -e "\n=== RUNNING PROCESSES (TOP 20) ===" | tee -a $LOGFILE
ps aux --sort=-%cpu | head -20 | tee -a $LOGFILE
ps aux --sort=-%mem | head -20 | tee -a $LOGFILE

echo -e "\n=== OPEN PORTS ===" | tee -a $LOGFILE
netstat -tulnp | grep LISTEN | tee -a $LOGFILE
ss -tulnp | tee -a $LOGFILE

echo -e "\n=== FIREWALL & SELINUX STATUS ===" | tee -a $LOGFILE
systemctl status firewalld | tee -a $LOGFILE
iptables -L -n | tee -a $LOGFILE
getenforce | tee -a $LOGFILE

echo -e "\n=== NETWORK CONFIGURATION ===" | tee -a $LOGFILE
ip a | tee -a $LOGFILE
ip r | tee -a $LOGFILE
cat /etc/resolv.conf | tee -a $LOGFILE
nmcli dev show | grep 'IP4.DNS' | tee -a $LOGFILE

echo -e "\n=== KERNEL PARAMETERS ===" | tee -a $LOGFILE
sysctl -a | grep -E 'net.core|net.ipv4|vm.swappiness|fs.file-max' | tee -a $LOGFILE

echo -e "\n=== SYSTEM LIMITS ===" | tee -a $LOGFILE
ulimit -a | tee -a $LOGFILE
cat /etc/security/limits.conf | tee -a $LOGFILE
cat /etc/security/limits.d/*.conf | tee -a $LOGFILE

echo -e "\n=== CRON JOBS ===" | tee -a $LOGFILE
crontab -l | tee -a $LOGFILE
ls -lah /etc/cron.* | tee -a $LOGFILE

echo -e "\n=== EXISTING USERS ===" | tee -a $LOGFILE
cat /etc/passwd | tee -a $LOGFILE

echo -e "\n=== SYSTEM GROUPS ===" | tee -a $LOGFILE
cat /etc/group | tee -a $LOGFILE

echo -e "\n=== USER LOGIN SESSIONS ===" | tee -a $LOGFILE
who | tee -a $LOGFILE
w | tee -a $LOGFILE
last | tee -a $LOGFILE

echo -e "\n=== AUTHENTICATION FAILURES ===" | tee -a $LOGFILE
grep "Failed password" /var/log/secure | tail -10 | tee -a $LOGFILE

echo -e "\n=== LOADED SYSTEMD SERVICES ===" | tee -a $LOGFILE
systemctl list-unit-files --type=service | tee -a $LOGFILE

echo -e "\n=== ACTIVE SYSTEMD SERVICES ===" | tee -a $LOGFILE
systemctl list-units --type=service --state=running | tee -a $LOGFILE

echo -e "\n=== DISABLED SYSTEMD SERVICES ===" | tee -a $LOGFILE
systemctl list-units --type=service --state=failed | tee -a $LOGFILE

echo -e "\n=== FSTAB SETTINGS ===" | tee -a $LOGFILE
cat /etc/fstab | tee -a $LOGFILE

echo -e "\n=== MOUNT SETTINGS ===" | tee -a $LOGFILE
mount | tee -a $LOGFILE

echo -e "\n=== TIME SETTINGS ===" | tee -a $LOGFILE
timedatectl | tee -a $LOGFILE
cat /etc/timezone 2>/dev/null | tee -a $LOGFILE
ntpq -p | tee -a $LOGFILE

echo -e "\n=== HARDWARE SETTINGS ===" | tee -a $LOGFILE
dmidecode -t memory | tee -a $LOGFILE
lshw -short | tee -a $LOGFILE

echo -e "\n=== SWAP USAGE ===" | tee -a $LOGFILE
swapon -s | tee -a $LOGFILE
cat /proc/meminfo | grep Swap | tee -a $LOGFILE

echo -e "\n=== FILE SYSTEM USAGE ===" | tee -a $LOGFILE
df -Th | tee -a $LOGFILE
du -sh /var/log/ | tee -a $LOGFILE
du -sh /tmp/ | tee -a $LOGFILE

echo -e "\n=== TOP IO WAIT PROCESSES ===" | tee -a $LOGFILE
iotop -o -n 5 | tee -a $LOGFILE

echo -e "\n=== NETWORK CONNECTIONS ===" | tee -a $LOGFILE
ss -s | tee -a $LOGFILE

echo -e "\n=== TCP CONNECTIONS PER STATE ===" | tee -a $LOGFILE
ss -ant | awk '{print $1}' | sort | uniq -c | tee -a $LOGFILE

echo -e "\n=== CHECK SYSTEM BOOT ERRORS ===" | tee -a $LOGFILE
dmesg -T | grep -i "error\|fail\|warn" | tail -20 | tee -a $LOGFILE

echo -e "\n[INFO] Log file generated at: $LOGFILE"
