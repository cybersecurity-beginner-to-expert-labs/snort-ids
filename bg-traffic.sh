#!/bin/bash

# Set source IP (local Kali Linux IP)
TARGET_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-container)
SOURCE_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' nginx-container)

# Set the destination port (80 for HTTP)
TARGET_PORT=8000

# Set the interval (in seconds) between each packet
INTERVAL=10  # Interval between packets in seconds

echo "Starting to send SYN packets from $SOURCE_IP to $TARGET_IP:$TARGET_PORT every $INTERVAL (s) to assist flushing snort buffers."

# Function to send SYN packets
send_syn_packets() {
  while true; do
    # Send a SYN packet using bash (without requiring scapy or external tools)
    # Creating a SYN packet with a simple raw TCP packet using netcat or bash
    sudo nmap -sS -p 5000-5100 $TARGET_IP
    sleep $INTERVAL  # Wait for the specified interval
  done
}

# Start sending SYN packets in the background
send_syn_packets &
