#!/bin/bash
# Check for target argument
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <target_ip_or_domain> <machine_name>"
    exit 1
fi

TARGET=$1
MACHINE_NAME=$2
# Create a directory for the target's recon data
OUTPUT_DIR="recon_$TARGET"
mkdir -p $OUTPUT_DIR

# Write the target IP to a file
echo $TARGET > $OUTPUT_DIR/target_ip.txt

# Run Masscan for quick port scanning
if ! test -f $OUTPUT_DIR/masscan_output.gnmap; then
	echo "Running Masscan..."
	sudo masscan -p1-65535 --rate=1000 -oG $OUTPUT_DIR/masscan_output.gnmap $TARGET
fi

# Extract open ports from Masscan output
OPEN_PORTS=$(grep -oP '\d{1,5}/open' $OUTPUT_DIR/masscan_output.gnmap | cut -d'/' -f1 | sort -n | tr '\n' ',' | sed 's/,$//')


# Check if any ports were found
if [ -z "$OPEN_PORTS" ]; then
	echo "No open ports found by Masscan."
	exit 1
else
	if ! test -f "$OUTPUT_DIR/nmap_output.txt"; then
	
		# Run Nmap scan on the discovered open ports
		echo "Running Nmap scan on discovered open ports: $OPEN_PORTS"
		nmap -sC -sV -A -Pn -p $OPEN_PORTS -oN $OUTPUT_DIR/nmap_output.txt $TARGET
	fi	
fi

# Detect redirects from the nmap scan
if ! test -f "$OUTPUT_DIR/websites_detected.txt"; then
    if ! grep -q "http-title: Did not follow redirect to" "$OUTPUT_DIR/nmap_output.txt"; then
	    echo "No matching lines found in Nmap results for Websites"
	else
	    echo "Checking Nmap results for Websites"
	    grep "http-title: Did not follow redirect to" "$OUTPUT_DIR/nmap_output.txt" | sed 's/|_http-title: Did not follow redirect to//g' > "$OUTPUT_DIR/websites_detected.txt"
	fi
fi

#Check for Web Service
if test -f "$OUTPUT_DIR/nmap_output.txt";then
	if grep -q '80/tcp open  http' $OUTPUT_DIR/nmap_output.txt ; then
	    echo "http://$TARGET" >> "$OUTPUT_DIR/websites_detected.txt"   
	fi
	if grep -q '443/tcp open  https' $OUTPUT_DIR/nmap_output.txt ; then
	    echo "https://$TARGET" >> "$OUTPUT_DIR/websites_detected.txt"   
	fi
fi

#SMB checking
if echo "$OPEN_PORTS" | grep -q  "\<445\>"; then
	if ! test -f "$OUTPUT_DIR/smb_output.txt"; then
		echo "Checking SMB Anno Access...."
		smbmap -H $TARGET -u anonymous -r -g $OUTPUT_DIR/smb_anno.tmp
		echo "Checking SMB GUEST Access...."
		smbmap -H $TARGET -u guest -r -g $OUTPUT_DIR/smb_guest.tmp
		sed 's/^/[ANNO]: /' $OUTPUT_DIR/smb_anno.tmp > $OUTPUT_DIR/smb_anno_prefix.tmp
		sed 's/^/[GUEST]: /' $OUTPUT_DIR/smb_guest.tmp > $OUTPUT_DIR/smb_guest_prefix.tmp
		cat "$OUTPUT_DIR/smb_anno_prefix.tmp" "$OUTPUT_DIR/smb_guest_prefix.tmp" > "$OUTPUT_DIR/smb_output.txt"
		rm -f "$OUTPUT_DIR/smb_anno_prefix.tmp" "$OUTPUT_DIR/smb_guest_prefix.tmp" "$OUTPUT_DIR/smb_anno.tmp" "$OUTPUT_DIR/smb_guest.tmp"
	fi
	if ! test -f "$OUTPUT_DIR/smb_users.txt"; then
		 crackmapexec smb $TARGET -u 'user' -p 'PASS' --rid-brute >> "$OUTPUT_DIR/smb_users.txt"
	fi 
fi
if test -f "$OUTPUT_DIR/smb_output.txt";then
	if ! test -f "$OUTPUT_DIR/smb_connect.txt";then
		while IFS= read -r line; do
		    # Extract username, host, share, and privileges information
		    username=$(echo "$line" | grep -o '\[.*\]' | sed 's/\[\(.*\)\]/\1/')
		    host=$(echo "$line" | awk -F 'host:' '{print $2}' | awk -F ', share:' '{print $1}')
		    share=$(echo "$line" | awk -F 'share:' '{print $2}' | awk -F ', privs:' '{print $1}')
		    privs=$(echo "$line" | awk -F ', privs:' '{print $2}' | awk -F ', isDir:' '{print $1}')

		    # Skip lines with no access privileges
		    if [ "$privs" = "NO_ACCESS" ]; then
			continue
		    fi

		    # Form smbclient connect command and write to output file
		    echo "smbclient //$host/$share -U $username -p "  >> "$OUTPUT_DIR/smb_connect.tmp"
		done < "$OUTPUT_DIR/smb_output.txt"
		sort -u "$OUTPUT_DIR/smb_connect.tmp" > "$OUTPUT_DIR/smb_connect.txt"
		rm "$OUTPUT_DIR/smb_connect.tmp"
	fi
fi
if test -f "$OUTPUT_DIR/smb_connect.txt"; then
    while IFS= read -r smb_connect_line; do
        # Extracting username, password, SMB_SHARE, and TARGET using awk
        SMB_USER=$(echo "$smb_connect_line" | awk -F' -U | -p ' '{print $2}')
        SMB_PASSWORD=$(echo "$smb_connect_line" | awk -F' -U | -p ' '{print $3}')
        SMB_SHARE=$(echo "$smb_connect_line" | awk -F'/' '{print $4}' | awk '{print $1}')
        TARGET=$(echo "$smb_connect_line" | awk -F'/' '{print $3}')
        # Create the destination folder
        DEST_FOLDER="$OUTPUT_DIR/${SMB_SHARE}_${SMB_USER}"
        if ! test -d "$DEST_FOLDER"; then
            mkdir -p "$DEST_FOLDER"
            # Check if a password is required
            if [[ -n "$SMB_PASSWORD" ]]; then
                smbclient "//10.10.11.16/$SMB_SHARE" -U "$SMB_USER" -p "$SMB_PASSWORD" -c "lcd \"$DEST_FOLDER\"; recurse; prompt; mget *"
            else
                smbclient "//10.10.11.16/$SMB_SHARE" -U "$SMB_USER" -N -c "lcd \"$DEST_FOLDER\"; recurse; prompt; mget *"
            fi
        fi
    done < "$OUTPUT_DIR/smb_connect.txt"
fi

# Create a hosts file with target IP and detected redirects
if ! test -f "$OUTPUT_DIR/hosts.txt"; then
	echo "$TARGET $MACHINE_NAME" >> "$OUTPUT_DIR/hosts.txt"
	if test -f "$OUTPUT_DIR/websites_detected.txt";then
		while IFS= read -r line; do
		    domain=$(echo "$line" | awk -F/ '{gsub(/:[0-9]+/, "", $3); print $3}')
		    echo "$TARGET $domain" >> "$OUTPUT_DIR/hosts.txt"
		done < "$OUTPUT_DIR/websites_detected.txt"
	fi
	while IFS= read -r line; do
	    domain=$(echo "$line" | awk -F/ '{gsub(/:[0-9]+/, "", $3); print $3}')
	    echo "$TARGET $domain" >> "$OUTPUT_DIR/hosts.txt"
	done < "$OUTPUT_DIR/websites_detected.txt"
fi
if ! test -f "$OUTPUT_DIR/enum4linux_output.txt"; then
	enum4linux -a $TARGET > $OUTPUT_DIR/enum4linux_output.txt
fi

# Add hosts to Host file
if [ -f "$OUTPUT_DIR/hosts.txt" ]; then
    echo "Removing existing entries from /etc/hosts"
    while IFS= read -r line; do
        # Remove existing entries from /etc/hosts
        sudo sed -i "/$line/d" /etc/hosts
    done < "$OUTPUT_DIR/hosts.txt"

    echo "Adding new entries from hosts.txt to /etc/hosts"
    # Add new entries from hosts.txt to /etc/hosts
    sudo tee -a /etc/hosts < "$OUTPUT_DIR/hosts.txt" >/dev/null
fi

#GoBuster Check
if test -f "$OUTPUT_DIR/websites_detected.txt";then
	while IFS= read -r line; do
	    domain=$(echo "$line" | awk -F/ '{gsub(/:[0-9]+/, "", $3); print $3}')
	    if ! test -f "$OUTPUT_DIR/gobuster_output_$domain.txt"; then
		    echo "Runing GoBuster on $line"
		    gobuster dir -u $line -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o  $OUTPUT_DIR/gobuster_output_$domain.txt}
	    fi
	done < "$OUTPUT_DIR/websites_detected.txt"
fi
#Nikto Check
while IFS= read -r line; do
    domain=$(echo "$line" | awk -F/ '{gsub(/:[0-9]+/, "", $3); print $3}')
    if ! test -f "$OUTPUT_DIR/nikto_output_$domain.txt"; then
	    echo "Runing Nikto on $line"
	    #gobuster dir -u $line -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -o  $OUTPUT_DIR/gobuster_output_$domain.txt}
	    nikto -h $line -output $OUTPUT_DIR/nikto_output_$domain.txt
    fi
done < "$OUTPUT_DIR/websites_detected.txt"



echo "Scanning completed. Results are saved in the $OUTPUT_DIR directory."
