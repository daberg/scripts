#!/bin/bash

# Stores an encypted secret in secure storage using secret-tool
# Outputs a suitable decryptor of the encrypted secret at the specified path

if [ "$#" -ne 2 ]; then
    echo "USAGE:    store-crypt.sh UNIQUEID DECDEST"
    exit 1
fi

ID=$1
DECDEST=$2

echo "Generating scripts"
sudo ./gen-crypt-scripts.sh
echo ""

exec 3>&1
SECR=$(sudo ./out.enc.sh | tee >(cat - >&3))
if echo "$SECR" | sed -n '3p' | grep -q 'Error'; then
    echo "Aborting..."
    exit 1
fi
echo "Storing secret"
echo -n "$(echo "$SECR" | sed -n '4p')" \
    | secret-tool store --label="$(id -un) encrypted storage" 'ID' "$ID"

echo "Compiling decrypting script"
sudo shc -o out.dec -f out.dec.sh
echo "Changing script permissions"
sudo chmod 701 out.dec
echo "Moving script to ${DECDEST}"
sudo mv ./out.dec "$DECDEST"

echo "Cleaning up"
sudo rm out.dec.sh
sudo rm out.enc.sh
sudo rm out.key
sudo rm out.dec.sh.x.c
