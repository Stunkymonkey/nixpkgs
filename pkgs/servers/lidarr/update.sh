#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl gnused nix-prefetch jq

set -e

dirname="$(dirname "$0")"

updateHash()
{
    version=$1
    arch=$2
    os=$3

    hashKey="${arch}-${os}_hash"

    url="https://github.com/Lidarr/Lidarr/releases/download/v$version/Lidarr.master.$version.$os-core-$arch.tar.gz"
    hash=$(nix-prefetch-url --type sha256 $url)
    sriHash="$(nix --extra-experimental-features nix-command hash to-sri --type sha256 $hash)"

    sed -i "s|$hashKey = \"[a-zA-Z0-9\/+-=]*\";|$hashKey = \"$sriHash\";|g" "$dirname/default.nix"
}

updateVersion()
{
    sed -i "s/version = \"[0-9.]*\";/version = \"$1\";/g" "$dirname/default.nix"
}

currentVersion=$(cd $dirname && nix eval --raw -f ../../.. lidarr.version)

latestTag=$(curl https://api.github.com/repos/Lidarr/Lidarr/releases/latest | jq -r ".tag_name")
latestVersion="$(expr $latestTag : 'v\(.*\)')"

if [[ "$currentVersion" == "$latestVersion" ]]; then
    echo "Lidarr is up-to-date: ${currentVersion}"
    exit 0
fi

updateVersion $latestVersion

updateHash $latestVersion x64 linux
updateHash $latestVersion arm64 linux
updateHash $latestVersion x64 osx
updateHash $latestVersion arm64 osx
