#!/bin/bash

# Function to display the main menu and get user's choice
function display_menu() {
    echo "========================================="
    echo "  Snort Lab Setup Script"
    echo "========================================="
    echo "1. Start everything from scratch (overwrite rules, pick this option if first time)"

    echo "2. Reset everything except rules (pick if you have added your own rules)"
    echo "Please choose an option (1 or 2): "
    read choice
}

# Function to install Snort if not already installed
function install_snort() {
    if ! command -v snort &> /dev/null
    then
        echo "Snort not found, installing..."
        sudo apt update
        sudo apt install -y snort awk
    else
        echo "Snort is already installed."
    fi
}

# Function to pull and run Nginx Docker container
function run_nginx_container() {
    echo "Pulling Nginx Docker image..."
    sudo docker pull nginx

    echo "Running Nginx container in detached mode..."
    sudo docker run -d --name nginx-container nginx
}

# Function to overwrite local.rules file with the new rule
function overwrite_rules() {
    SOURCE_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.Gateway}}{{end}}' nginx-container)
    NGINX_CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx-container)

    echo "Local IP address (eth0): $SOURCE_IP"
    echo "Nginx container IP: $NGINX_CONTAINER_IP"
    
    RULES_FILE="/etc/snort/rules/local.rules"

    echo "Overwriting $RULES_FILE with new rule..."
    echo -e "\n# Rule to detect NMAP scan from $SOURCE_IP to Nginx container ($NGINX_CONTAINER_IP)\nalert tcp $SOURCE_IP any -> $NGINX_CONTAINER_IP 25 (msg:\"NMAP Scan to FTP(25) Port Detected\"; flags:S; sid:1000003;)" > $RULES_FILE
    #echo -e "\n\n# Rule to detect malicious path traversal attempt from $SOURCE to Nginx container ($NGINX_CONTINER_IP)\nalert tcp $SOURCE_IP any -> $NGINX_CONTAINER_IP 80 (msg:\"WEB-ATTACK: Path Traversal Attempt (GET /etc/passwd)\"; http_uri; content:\"etc/passwd\"; sid:1000009; rev:1;)" >> $RULES_FILE
}

# Function to run Snort with the given rule
function run_snort() {
    
    sudo kill -9 $(pgrep snort3) 2>/dev/null
    echo "Running Snort with custom rule..."
    sudo snort -R /etc/snort/rules/local.rules -i docker0 -A alert_fast
}

# Function to run background traffic script
function run_background_traffic() {
    sudo kill -9 $(pgrep bg-traffic) 2>/dev/null
    sudo chmod +x ./bg-traffic.sh
    sleep 1
    sudo ./bg-traffic.sh &
}

# Function to clean up (stop and remove all containers except for Nginx)
function cleanup_containers() {
    echo "Stopping and removing all Docker containers..."
    sudo docker stop $(sudo docker ps -aq) 2>/dev/null
    sleep 1
    sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null
}

# Main script logic
display_menu
case $choice in
    1)  # Option 1: Start everything from scratch (overwrite rules)
        # Install Snort
        install_snort

        # Clean up (stop and remove all containers except for the one running Nginx)
        cleanup_containers
        
        # Pull and run Nginx container
        run_nginx_container
        
        # Overwrite the local.rules file with the new rule
        overwrite_rules
        
        # Run the background traffic script
        run_background_traffic

        # Run Snort with the new rule
        run_snort
        ;;
        
    2)  # Option 2: Reset everything except local.rules (preserve rules)
        # Install Snort
        install_snort
        
        # Clean up (stop and remove all containers except for the one running Nginx)
        cleanup_containers
        
        # Pull and run Nginx container
        run_nginx_container

        # Don't overwrite the local.rules file, keeping it intact
        
        # Run the background traffic script
        run_background_traffic

        # Run Snort with the existing rules
        run_snort
        ;;
        
    *)  # Invalid choice
        echo "Invalid option. Exiting..."
        exit 1
        ;;
esac

