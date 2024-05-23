#!/bin/bash

# Define your API key if applicable (replace with your actual key)
API_KEY="bb429e5eff579ca7e2f4b0b43e052a4f"

# Check for target argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target_ip_or_domain>"
    exit 1
fi

TARGET=$1

# Create a directory for the target's recon data
OUTPUT_DIR="recon_$TARGET"
mkdir -p $OUTPUT_DIR

# Run Masscan for quick port scanning
echo "Running Masscan..."
sudo masscan -p1-65535 --rate=10000 -oG $OUTPUT_DIR/masscan_output.gnmap $TARGET

# Extract open ports from Masscan output
OPEN_PORTS=$(grep -oP '\d{1,5}/open' $OUTPUT_DIR/masscan_output.gnmap | cut -d'/' -f1 | sort -n | tr '\n' ',' | sed 's/,$//')

# Check if any ports were found
if [ -z "$OPEN_PORTS" ]; then
    echo "No open ports found by Masscan."
    exit 1
fi

# Run Nmap scan on the discovered open ports
echo "Running Nmap scan on discovered open ports: $OPEN_PORTS"
nmap -sC -sV -A -Pn -p $OPEN_PORTS -oN $OUTPUT_DIR/nmap_output.txt $TARGET

# Run Amass for subdomain enumeration if the target is a domain
if [[ "$TARGET" == *.* ]]; then
    echo "Running Amass..."
    amass enum -d $TARGET -o $OUTPUT_DIR/amass_output.txt
fi

# Run Nikto for web server vulnerability scanning
echo "Running Nikto..."
nikto -h http://$TARGET -output $OUTPUT_DIR/nikto_output.txt

# Run Gobuster for directory brute-forcing
echo "Running Gobuster..."
gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o $OUTPUT_DIR/gobuster_output.txt

# Run Enum4linux for SMB enumeration
echo "Running Enum4linux..."
enum4linux -a $TARGET > $OUTPUT_DIR/enum4linux_output.txt

# Example API usage (replace with actual API endpoint and usage)
if [ ! -z "$API_KEY" ]; then
    echo "Running additional API-based checks..."
    curl -H "Authorization: Bearer $API_KEY" "https://api.example.com/v1/scan?target=$TARGET" -o $OUTPUT_DIR/api_scan_output.txt
fi

echo "Reconnaissance completed. Results are saved in the $OUTPUT_DIR directory."

