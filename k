#!/usr/bin/env bash
set +xe

KX_PATH="$HOME/.kx"
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
if [ ! -z "$KUBECONFIG" ]; then
  if [ "$OS" == "darwin" ]; then
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | shasum -a 256 | cut -c1-5)
  else
    KUBECONFIG_HASH=$(echo "$KUBECONFIG" | sha256sum | cut -c1-5)
  fi
  VERSION_CACHE_FILE="$KX_PATH/cache/$KUBECONFIG_HASH"
  TARGET_VERSION=$(cat "$VERSION_CACHE_FILE" 2> /dev/null)
fi

# Ensure we have at least 1 kubectl version
KNOWN_VERSION="v1.16.3"
KNOWN_TARGET=$KX_PATH/kubectl-$KNOWN_VERSION
KUBECTL_PATH=$(command -v kubectl)
if [ ! -z $KUBECTL_PATH ]; then
  KNOWN_TARGET=$KUBECTL_PATH
elif [ ! -f "$KNOWN_TARGET" ]; then
  curl -L -o $KNOWN_TARGET "https://storage.googleapis.com/kubernetes-release/release/$KNOWN_VERSION/bin/$OS/amd64/kubectl"
  chmod +x $KNOWN_TARGET
fi

# Get the server version from the server if not cached
if [ -z "$TARGET_VERSION" ]; then
  TARGET_VERSION=$($KNOWN_TARGET version -o json | jq -r '.serverVersion.gitVersion')
  if [ -z "$TARGET_VERSION" ] || [ "$TARGET_VERSION" == "null" ]; then
    echo "Unable to get version information from cluster"
    exit 1
  fi
  if [ $(echo $TARGET_VERSION | egrep "alpha|beta|rc") ]; then
    TARGET_VERSION=$(echo $TARGET_VERSION | cut -d'.' -f1-4)
  else
    TARGET_VERSION=$(echo $TARGET_VERSION | cut -d'.' -f1-3)
  fi
fi

# Fill the cache if possible
if [ ! -z "$KUBECONFIG" ]; then
  echo "$TARGET_VERSION" > "$VERSION_CACHE_FILE"
fi

TARGET=$KX_PATH/kubectl-$TARGET_VERSION

if [ ! -f $TARGET ]; then
  curl -L -o $TARGET "https://storage.googleapis.com/kubernetes-release/release/$TARGET_VERSION/bin/$OS/amd64/kubectl"
  chmod +x $TARGET
fi

$TARGET "$@"
