#!/bin/bash

# build-repo.sh
cd "$(dirname "$0")/.." || exit 1
source scripts/common.sh

build_package_repo() {
    local config_file=$1
    local package_info=$(cat "$config_file")

    local package_name=$(echo "$package_info" | jq -r .name)
    local github_repo=$(echo "$package_info" | jq -r .source.repo)

    echo "Processing package: $package_name"
    local new_version=$(get_latest_version_gh "$github_repo")

    local current_version=$(cat "version-lock/${package_name}.lock" 2>/dev/null || echo "0")
    echo "Current version: $current_version"
    echo "New version: $new_version"

    if [ "$current_version" = "$new_version" ]; then
        echo "${package_name} is already up to date"
        return 0
    fi
    echo "Updating ${package_name} from ${current_version} to ${new_version}"

    create_repo_structure "$package_name"

    local architectures=$(echo "$package_info" | jq -r '.package.architectures[]')
    for arch in $architectures; do
        local pattern=$(echo "$package_info" | jq -r ".source.asset_patterns.${arch}")
        download_package_gh "$github_repo" "$new_version" "$arch" "$pattern" "$package_name"
    done

    echo "Updating version lock file"
    echo "$new_version" >"version-lock/${package_name}.lock"
    echo "Version lock file updated"
}

generate_repo_metadata() {
    ROOT_DIR="$(cd "$(dirname "$(dirname "$0")")" && pwd)"
    CONF_FILE="${ROOT_DIR}/apt-ftparchive.conf"

    for arch in amd64 arm64 armhf; do
        mkdir -p "dists/stable/main/binary-${arch}"
        if ls pool/*/*_${arch}.deb 1>/dev/null 2>&1; then
            dpkg-scanpackages --arch ${arch} pool/ >"dists/stable/main/binary-${arch}/Packages"
            gzip -k -f "dists/stable/main/binary-${arch}/Packages"
        fi
    done

    cd dists/stable
    apt-ftparchive -c "${CONF_FILE}" release . >Release
    gpg --batch --yes --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" --clearsign -o InRelease Release
    gpg --batch --yes --pinentry-mode loopback --passphrase "$GPG_PASSPHRASE" -abs -o Release.gpg Release
    cd ../..
}

if [ "$1" = "--generate-metadata" ]; then
    generate_repo_metadata
    exit 0
fi

if [ -f "$1" ]; then
    build_package_repo "$1"
else
    echo "Usage: $0 <config-file> or $0 --generate-metadata"
    exit 1
fi
