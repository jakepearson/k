#!/usr/bin/env bash
set +xe

# DEBUG
# true => verbose (`set -xe`)
# <anything_else> => nothing
DEBUG=${DEBUG:-false}

if [[ "$DEBUG" == "true" ]];
then
  set -xe
  echo "Enabled verbose logging."
fi


KX_PATH="${KX_PATH:-$HOME/.kx}"
mkdir -p "$KX_PATH/cache"

case "$OSTYPE" in
  *arwin*)
    OS="darwin"
    ;;
  *in32* | *indows*)
    OS="windows"
    ;;
  *)
    OS="linux"
esac

# Attempt to load the server version from cache
if [ -n "$KUBECONFIG" ]; then
  if [ "$OS" == "darwin" ]; then
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | shasum -a 256 | cut -c1-5)
  else
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | sha256sum | cut -c1-5)
  fi
  VERSION_CACHE_FILE="$KX_PATH/cache/$KUBECONFIG_HASH"
  TARGET_VERSION=$(cat "$VERSION_CACHE_FILE" 2> /dev/null)
fi

# Use Correct CPU Architecture
CPU_ARCHITECTURE=$(uname -m)
case $CPU_ARCHITECTURE in
  armv5*) CPU_ARCHITECTURE="armv5";;
  armv6*) CPU_ARCHITECTURE="armv6";;
  armv7*) CPU_ARCHITECTURE="arm";;
  aarch64) CPU_ARCHITECTURE="arm64";;
  x86) CPU_ARCHITECTURE="386";;
  x86_64) CPU_ARCHITECTURE="amd64";;
  i686) CPU_ARCHITECTURE="386";;
  i386) CPU_ARCHITECTURE="386";;
esac

# Ensure we have at least 1 kubectl version
#
# This is used to make it easier to get the server version, which
# is an API that rarely changes... at least that is the hope
KNOWN_VERSION="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
LOCAL_KUBECTL=$KX_PATH/kubectl-$KNOWN_VERSION
if [ ! -f "$LOCAL_KUBECTL" ]; then
  curl -L -o "$LOCAL_KUBECTL" "https://storage.googleapis.com/kubernetes-release/release/$KNOWN_VERSION/bin/$OS/$CPU_ARCHITECTURE/kubectl" > /dev/null 2>&1
  chmod +x "$LOCAL_KUBECTL"
fi

# Get the server version from the server if not cached
if [ -z "$TARGET_VERSION" ]; then
  TARGET_VERSION=$($LOCAL_KUBECTL version -o json | jq -r '.serverVersion.gitVersion')
  if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" == "null" ]; then
    echo "Unable to get version information from cluster"
    exit 1
  fi
  # watch out for different non-stable release versions
  if echo "$TARGET_VERSION" | grep -E "alpha|beta|rc" > /dev/null 2>&1
  then
    TARGET_VERSION=$(echo $TARGET_VERSION | cut -d'.' -f1-4)
  else
    TARGET_VERSION=$(echo $TARGET_VERSION | cut -d'.' -f1-3)
  fi

  # watch out for the custom EKS version
  if echo "$TARGET_VERSION" | grep -E "eks" > /dev/null 2>&1
  then
    TARGET_VERSION=$(echo $TARGET_VERSION | cut -d'-' -f1)
  fi
fi

# Fill the cache if possible
if [ -n "$KUBECONFIG" ]; then
  echo "$TARGET_VERSION" > "$VERSION_CACHE_FILE"
fi

TARGET=$KX_PATH/kubectl-$TARGET_VERSION

if [ ! -f "$TARGET" ]; then
  curl -L -o "$TARGET" "https://storage.googleapis.com/kubernetes-release/release/$TARGET_VERSION/bin/$OS/$CPU_ARCHITECTURE/kubectl" > /dev/null 2>&1
  chmod +x "$TARGET"
fi

$TARGET "$@"
