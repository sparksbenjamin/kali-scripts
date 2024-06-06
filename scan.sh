#!/bin/bash
# Check for target argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target_ip_or_domain>"
    exit 1
fi

TARGET=$1

# Create a directory for the target's recon data
OUTPUT_DIR="recon_$TARGET"
mkdir -p $OUTPUT_DIR

# Write the target IP to a file
echo $TARGET > $OUTPUT_DIR/target_ip.txt

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

# Detect redirects from the nmap scan
grep -i "Location: " $OUTPUT_DIR/nmap_output.txt | awk '{print $2}' > $OUTPUT_DIR/websites_detected.txt

# Create a hosts file with target IP and detected redirects
while IFS= read -r line; do
    domain=$(echo $line | awk -F/ '{print $3}')
    echo "$TARGET $domain" >> $OUTPUT_DIR/hosts
done < $OUTPUT_DIR/websites_detected.txt

echo "Scanning completed. Results are saved in the $OUTPUT_DIR directory."
