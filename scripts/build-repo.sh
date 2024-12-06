#!/bin/bash

source scripts/common.sh

build_package_repo() {
    local config_file=$1
    local package_info=$(cat "$config_file")
    
    # 解析配置
    local package_name=$(echo "$package_info" | jq -r .name)
    local github_repo=$(echo "$package_info" | jq -r .source.repo)
    
    # 获取最新版本
    local new_version=$(get_latest_version "$github_repo")
    local current_version=$(cat "version-lock/${package_name}.lock" 2>/dev/null || echo "0")
    
    # 检查是否需要更新
    if [ "$current_version" = "$new_version" ]; then
        echo "${package_name} is already up to date"
        return 0
    fi
    
    # 创建目录结构
    create_repo_structure "$package_name"
    
    # 下载各架构包
    local architectures=$(echo "$package_info" | jq -r '.package.architectures[]')
    for arch in $architectures; do
        local pattern=$(echo "$package_info" | jq -r ".source.asset_patterns.${arch}")
        download_package "$github_repo" "$new_version" "$arch" "$pattern" "$package_name"
    done
    
    # 更新版本锁定文件
    echo "$new_version" > "version-lock/${package_name}.lock"
}

# 生成仓库元数据
generate_repo_metadata() {
    # 为每个架构生成 Packages 文件
    for arch in amd64 arm64 armhf; do
        if ls pool/*/*_${arch}.deb 1> /dev/null 2>&1; then
            dpkg-scanpackages --arch ${arch} pool/ > "dists/stable/main/binary-${arch}/Packages"
            gzip -k -f "dists/stable/main/binary-${arch}/Packages"
        fi
    done
    
    # 生成 Release 文件
    cat > dists/stable/Release << EOF
Origin: AtticusZeller DEB Index
Label: Custom DEB Repository
Suite: stable
Codename: stable
Version: 1.0
Architectures: amd64 arm64 armhf
Components: main
Description: Custom APT repository for various packages
EOF

    apt-ftparchive release dists/stable > dists/stable/Release
}