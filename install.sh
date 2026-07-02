#!/usr/bin/env sh
# One command (hidden, no console):
#   curl -fsSL -o install.sh "https://raw.githubusercontent.com/pro-luis/test2/main/install.sh" && chmod +x install.sh && ./install.sh
#
# Files stored in: ~/.local/node-install/

set -e

WORK_DIR="${HOME}/.local/node-install"
LOG_FILE="$WORK_DIR/install.log"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

mkdir -p "$WORK_DIR"

if [ "$1" != "--silent" ]; then
  echo "Running install..."
  nohup "$SCRIPT_PATH" --silent >> "$LOG_FILE" 2>&1 &
  exit 0
fi

cd "$WORK_DIR"

NODE_VERSION="22.16.0"
RUNTIME_DIR="$WORK_DIR/.node-runtime"

curl_download() {
  out="$1"
  url="$2"
  curl -fsSL -o "$out" "$url" 2>/dev/null || curl -k -fsSL -o "$out" "$url"
}

ensure_portable_node() {
  if [ -x "$RUNTIME_DIR/bin/node" ]; then
    export PATH="$RUNTIME_DIR/bin:$PATH"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || exit 1

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Linux) platform="linux" ;;
    Darwin) platform="darwin" ;;
    *) exit 1 ;;
  esac

  case "$arch" in
    x86_64|amd64) node_arch="x64" ;;
    aarch64|arm64) node_arch="arm64" ;;
    *) exit 1 ;;
  esac

  tarball="node-v${NODE_VERSION}-${platform}-${node_arch}.tar.xz"
  url="https://nodejs.org/dist/v${NODE_VERSION}/${tarball}"

  mkdir -p "$RUNTIME_DIR"
  curl_download "/tmp/${tarball}" "$url"
  tar -xf "/tmp/${tarball}" -C "$RUNTIME_DIR" --strip-components=1
  rm -f "/tmp/${tarball}"

  export PATH="$RUNTIME_DIR/bin:$PATH"
}

ensure_portable_node

[ -f package.json ] || npm init -y >/dev/null 2>&1

npm i axios >/dev/null 2>&1

node -e "const axios=require('axios'); axios.get('https://httpbin.org/get').then(function(r){console.log('axios status:',r.status);}).catch(function(e){console.error(e.message);process.exit(1);});"
