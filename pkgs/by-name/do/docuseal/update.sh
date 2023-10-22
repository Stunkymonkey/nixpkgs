#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl bundix git ruby_3_2 pkg-config xmlstarlet nix-update

set -eu -o pipefail
cd "$(dirname "$(readlink -f "$0")")"

latest=$(curl https://github.com/docusealco/docuseal/tags.atom | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -m /atom:feed/atom:entry -v atom:title -n | head -n1)
echo "Updating docuseal to $latest"

sed -i "s#refs/tags/.*#refs/tags/$latest\"#" Gemfile

rm -f gemset.nix Gemfile.lock Gemfile

export BUNDLE_FORCE_RUBY_PLATFORM=1
bundle lock
bundix -l

cd "../../../../"
nix-update docuseal --version "$latest"
