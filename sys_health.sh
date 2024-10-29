#!/bin/bash

# Set output file
output_file="system_health_report.txt"
> "$output_file"  # Clear the file if it exists

# Helper function to write topics and subtopics with command and result
write_topic() {
  echo -e "\n## $1" >> "$output_file"
  echo -e "------------------------------------\n" >> "$output_file"
}

write_subtopic() {
  echo -e "\n### $1\n" >> "$output_file"
}

write_command() {
  echo -e "\nCommand executed: $1" >> "$output_file"
  echo -e "Output:\n" >> "$output_file"
  eval "$1" >> "$output_file" 2>&1
}

write_assessment() {
  echo -e "Assessment: $1\n" >> "$output_file"
}

# Start Health Checks

### 1. System Information ###
write_topic "System Information"

# OS Version
write_subtopic "Operating System Version"
command="cat /etc/os-release"
write_command "$command"
write_assessment "OS version information collected"

### 2. CPU Health and Usage ###
write_topic "CPU Health and Usage"

# CPU Load and Utilization
write_subtopic "CPU Load and Utilization"
command="top -bn1 | grep 'load average'"
write_command "$command"
load=$(top -bn1 | grep "load average" | awk '{print $12}' | sed 's/,//')
if (( $(echo "$load < 1" | bc -l) )); then
  write_assessment "CPU load is low"
elif (( $(echo "$load < 2" | bc -l) )); then
  write_assessment "CPU load is average"
else
  write_assessment "CPU load is high"
fi

# CPU Core Utilization
write_subtopic "CPU Core Utilization"
command="mpstat -P ALL 1 1"
write_command "$command"
write_assessment "Per-core utilization analyzed"

# CPU Interrupts and Context Switches
write_subtopic "CPU Interrupts and Context Switches"
command="vmstat 1 5"
write_command "$command"
write_assessment "Interrupts and context switches checked over time"

### 3. Memory Health and Usage ###
write_topic "Memory Health and Usage"

# Memory Usage Summary
write_subtopic "Memory Usage Summary"
command="free -h"
write_command "$command"
free_mem=$(free | grep Mem | awk '{print $4/$2 * 100.0}')
if (( $(echo "$free_mem > 20.0" | bc -l) )); then
  write_assessment "Memory usage is within safe limits"
else
  write_assessment "Memory usage is high"
fi

# Memory Usage per Process
write_subtopic "Memory Usage per Process"
command="ps aux --sort=-%mem | head -n 10"
write_command "$command"
write_assessment "Top memory-consuming processes identified"

# Detailed Memory Usage
write_subtopic "Detailed Memory Information"
command="cat /proc/meminfo"
write_command "$command"
write_assessment "Detailed memory stats observed"

### 4. Disk Health and Usage ###
write_topic "Disk Health and Usage"

# Disk Space Usage
write_subtopic "Disk Space Usage"
command="df -h"
write_command "$command"
write_assessment "Disk space usage for all filesystems listed"

# Disk Inode Usage
write_subtopic "Disk Inode Usage"
command="df -i"
write_command "$command"
write_assessment "Inode usage for all filesystems listed"

# Disk I/O Performance
write_subtopic "Disk I/O Performance"
command="iostat -xz 1 3"
write_command "$command"
write_assessment "Disk I/O performance (utilization, latency, throughput) analyzed over 3 seconds"

# Identify Disk Errors
write_subtopic "Identify Disk Errors"
command="dmesg | grep -i error"
write_command "$command"
write_assessment "Disk-related errors checked in system logs"

# Disk Health (SMART)
write_subtopic "Disk Health (SMART)"
command="sudo smartctl -a /dev/sda"
write_command "$command"
write_assessment "Full SMART health status of /dev/sda checked"

### 5. Network Health and Usage ###
write_topic "Network Health and Usage"

# Network Configuration
write_subtopic "Network Configuration"
command="ip addr show"
write_command "$command"
write_assessment "IP address configuration observed"

# DNS Servers from resolv.conf
write_subtopic "DNS Servers and Connectivity Test"
dns_servers=$(grep -E "^nameserver" /etc/resolv.conf | awk '{print $2}')
for dns in $dns_servers; do
  echo -e "\nDNS Server: $dns" >> "$output_file"
  command="ping -c 4 $dns"
  write_command "$command"
  if ping -c 1 "$dns" &>/dev/null; then
    write_assessment "DNS server $dns is reachable"
  else
    write_assessment "DNS server $dns is not reachable"
  fi
done

# DNS Query Test
write_subtopic "DNS Query Test"
command="nslookup google.com"
write_command "$command"
write_assessment "DNS query for google.com completed"

# Network Bandwidth Usage
write_subtopic "Network Bandwidth Usage"
command="iftop -t -s 10"
write_command "$command"
write_assessment "Network bandwidth usage observed for 10 seconds"

# Active Network Connections
write_subtopic "Active Network Connections"
command="sudo ss -tupn"
write_command "$command"
write_assessment "Active network connections listed"

### 6. System Configuration ###
write_topic "System Configuration"

# YUM Repository Configuration
write_subtopic "YUM Repository Configuration"
command="yum repolist"
write_command "$command"
write_assessment "YUM repositories listed"

# NTP Configuration
write_subtopic "NTP Configuration"
command="timedatectl status"
write_command "$command"
write_assessment "NTP synchronization status checked"

# Active Services
write_subtopic "Active Services"
command="systemctl list-units --type=service --state=active"
write_command "$command"
write_assessment "List of active services observed"

### 7. Hardware and System Information ###
write_topic "Hardware and System Information"

# CPU Information
write_subtopic "CPU Information"
command="lscpu"
write_command "$command"
write_assessment "Detailed information on CPU"

# Memory Details
write_subtopic "Memory Details"
command="dmidecode -t memory"
write_command "$command"
write_assessment "Hardware-level memory details retrieved"

# Disk Layout and Filesystems
write_subtopic "Disk Layout and Filesystems"
command="lsblk -f"
write_command "$command"
write_assessment "Disk layout and filesystems analyzed"

### 8. Log Analysis ###
write_topic "Log Analysis"

# General System Logs for Errors
write_subtopic "General System Logs for Errors"
command="sudo journalctl -p 3 -xb"
write_command "$command"
write_assessment "Errors in system logs from the current boot checked"

# Kernel Logs
write_subtopic "Kernel Logs"
command="dmesg | tail -n 20"
write_command "$command"
write_assessment "Recent kernel messages checked for errors"

### Completion Message
echo -e "\nSystem health assessment completed. Check $output_file for details."
