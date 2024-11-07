#!/bin/bash -eu

version=$1

mkdir -p harvester-$version
cd harvester-$version

wget https://releases.rancher.com/harvester/$version/harvester-$version-amd64.iso
wget https://releases.rancher.com/harvester/$version/harvester-$version-amd64.sha512
wget https://releases.rancher.com/harvester/$version/harvester-$version-initrd-amd64
wget https://releases.rancher.com/harvester/$version/harvester-$version-vmlinuz-amd64
wget https://releases.rancher.com/harvester/$version/harvester-$version-rootfs-amd64.squashfs
wget https://releases.rancher.com/harvester/$version/version.yaml || true

