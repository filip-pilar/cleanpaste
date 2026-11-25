#!/bin/zsh
# Publishes a release: ./release.sh 0.2.0
# Builds a universal binary for macOS 12 and later, tags the commit, creates the GitHub
# release (which the curl installer downloads) and points the Homebrew formula at it.
set -euo pipefail
cd "${0:A:h}"

version=${1:?usage: ./release.sh <version>, e.g. ./release.sh 0.2.0}
tag=v$version
asset=cleanpaste-macos-universal

[[ -z "$(git status --porcelain)" ]] || { echo "Commit your changes first." >&2; exit 1; }
./test.sh

mkdir -p build
for arch in arm64 x86_64; do
  swiftc -O -wmo -Xlinker -dead_strip -target $arch-apple-macos12 Sources/*.swift -o build/cleanpaste-$arch
done
lipo -create build/cleanpaste-arm64 build/cleanpaste-x86_64 -output build/$asset
codesign -s - -f build/$asset
codesign -v build/$asset
sha=$(shasum -a 256 build/$asset | cut -d' ' -f1)

git tag $tag
git push -q origin main $tag
gh release create $tag build/$asset --title $tag --generate-notes

tap=$(mktemp -d)
gh repo clone filip-pilar/homebrew-tap $tap -- -q
sed -i '' -e "s|/download/v[^/]*/|/download/$tag/|" \
          -e "s|sha256 \"[^\"]*\"|sha256 \"$sha\"|" $tap/Formula/cleanpaste.rb
git -C $tap commit -qam "cleanpaste $version"
git -C $tap push -q
echo "Released $tag. Homebrew users get it with: brew upgrade cleanpaste"
