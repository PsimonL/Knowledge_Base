#!/bin/bash

# Step 1: Convert the SSH private key into a format that John the Ripper can understand
# Using ssh2john.py script from the John the Ripper package
# Replace <<<ID>>> with the actual ID of private key file
python3 /opt/john/ssh2john.py id_rsa_<<<ID>>>.id_rsa > id_rsa_hash.txt

# Step 2: Use John the Ripper with the rockyou.txt wordlist to crack the password of the private key
john --wordlist=/usr/share/wordlists/rockyou.txt id_rsa_hash.txt

# Step 3: Display the cracked password for the SSH private key, if found
john --show id_rsa_hash.txt
