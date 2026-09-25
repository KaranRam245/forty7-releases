#!/bin/sh
# Install the forte-7 CLI from a GitHub release.
#
#   curl -fsSL https://raw.githubusercontent.com/KaranRam245/wednesday/main/forte-7/scripts/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --version 1.2.3 --bin-dir /usr/local/bin
#
# With no --version it installs the latest `forte-7-v*` release. macOS on Apple
# Silicon only for now; other platforms exit with a clear message.
set -eu

REPO="${FORTE7_REPO:-KaranRam245/forty7-releases}"
BIN_NAME="forty7-cli"
TARGET="aarch64-apple-darwin"
VERSION=""
BIN_DIR="${FORTE7_BIN_DIR:-$HOME/.local/bin}"

die() { echo "install: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="${2:?--version needs a value}"; shift 2 ;;
    --bin-dir) BIN_DIR="${2:?--bin-dir needs a value}"; shift 2 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option '$1'" ;;
  esac
done

os="$(uname -s)"
arch="$(uname -m)"
[ "$os" = "Darwin" ] || die "only macOS is supported right now (got $os)"
[ "$arch" = "arm64" ] || die "only Apple Silicon is supported right now (got $arch)"

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

if [ -z "$VERSION" ]; then
  # Newest forte-7 release tag, resolved without needing a GitHub token.
  VERSION="$(
    curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=100" \
      | grep '"tag_name"' \
      | sed -n 's/.*"tag_name": *"forty7-v\([^"]*\)".*/\1/p' \
      | head -1
  )"
  [ -n "$VERSION" ] || die "could not resolve the latest forte-7 release; pass --version X.Y.Z"
fi

TAG="forty7-v$VERSION"
ASSET="$BIN_NAME-$VERSION-$TARGET.tar.gz"
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "install: downloading $TAG ($TARGET)"
curl -fsSL "$URL" -o "$tmp/$ASSET" || die "download failed: $URL"

if curl -fsSL "$URL.sha256" -o "$tmp/$ASSET.sha256" 2>/dev/null; then
  expected="$(awk '{print $1}' "$tmp/$ASSET.sha256")"
  actual="$(shasum -a 256 "$tmp/$ASSET" | awk '{print $1}')"
  [ "$expected" = "$actual" ] || die "checksum mismatch (expected $expected, got $actual)"
else
  echo "install: no published checksum for $ASSET, skipping verification" >&2
fi

tar -xzf "$tmp/$ASSET" -C "$tmp"
[ -f "$tmp/$BIN_NAME" ] || die "$BIN_NAME missing from $ASSET"

mkdir -p "$BIN_DIR"
# Replace rather than write in place, so a running copy is not clobbered.
mv "$tmp/$BIN_NAME" "$BIN_DIR/$BIN_NAME.new"
chmod +x "$BIN_DIR/$BIN_NAME.new"
mv "$BIN_DIR/$BIN_NAME.new" "$BIN_DIR/$BIN_NAME"

# Downloaded binaries are quarantined by Gatekeeper; this is an ad-hoc unsigned
# build, so clear the attribute rather than make the user right-click it open.
xattr -d com.apple.quarantine "$BIN_DIR/$BIN_NAME" 2>/dev/null || true

echo "install: installed $BIN_NAME $VERSION to $BIN_DIR/$BIN_NAME"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "install: $BIN_DIR is not on your PATH; add: export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
