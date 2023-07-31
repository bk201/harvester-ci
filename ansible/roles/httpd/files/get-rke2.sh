#!/bin/bash -eux

VERSION=$1

mkdir -p $VERSION

cd $VERSION

wget https://github.com/rancher/rke2/releases/download/$VERSION/rke2-images.linux-amd64.tar.zst
wget https://github.com/rancher/rke2/releases/download/$VERSION/rke2-images.linux-amd64.txt

wget https://github.com/rancher/rke2/releases/download/$VERSION/rke2-images-multus.linux-amd64.txt

wget https://github.com/rancher/rke2/releases/download/$VERSION/rke2-images-harvester.linux-amd64.tar.zst
wget https://github.com/rancher/rke2/releases/download/$VERSION/rke2-images-harvester.linux-amd64.txt

# verify
wget https://github.com/rancher/rke2/releases/download/$VERSION/sha256sum-amd64.txt
sha256sum -c --ignore-missing sha256sum-amd64.txt
