#!/bin/bash
set -e


if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi


REPO_NAME="deb-index"


echo "Removing GPG key..."
rm -f "/etc/apt/keyrings/${REPO_NAME}.gpg"

echo "Removing repository..."
rm -f "/etc/apt/sources.list.d/${REPO_NAME}.list"

echo "Updating package lists..."
apt update

echo "Repository successfully removed!"
