#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "WARNING: not running as root"
fi

key=$(openssl rand -base64 20)

install -m 711 /dev/null out.enc.sh
install -m 711 /dev/null out.dec.sh
install -m 600 /dev/null out.key

printf "$key" >> out.key
echo "Encryption key written to out.key"

printf 'echo "Type in secret:"
read -s password

echo "Type secret again"
read -s passcheck

if [ "$password" != "$passcheck" ]; then
    echo "Secrets do not match"
    exit 1
fi

echo "$password" | openssl aes-256-cbc -a -salt -k' >> out.enc.sh
printf " '${key}' 2>/dev/null" >> out.enc.sh
echo "Encrypting script written to out.enc.sh"

printf '#!/bin/bash
if [ -z "$1" ]; then
    exit 1
fi
echo "$1" | openssl aes-256-cbc -a -d -salt -k' >> out.dec.sh
printf " '${key}' 2>/dev/null" >> out.dec.sh
echo "Decrypting script written to out.dec.sh"
