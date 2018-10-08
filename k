#!/usr/bin/env bash
set +x

KX_PATH="$HOME/.kx"
mkdir -p "$KX_PATH"
TARGET_VERSION=$(kubectl version -o json | jq -r '.serverVersion.gitVersion')
TARGET=$KX_PATH/kubectl-$TARGET_VERSION

if [ ! -f $TARGET ]; then
  cd "$KX_PATH"
  curl -LO "https://storage.googleapis.com/kubernetes-release/release/$TARGET_VERSION/bin/darwin/amd64/kubectl"
  mv $KX_PATH/kubectl $TARGET
  chmod +x $TARGET
fi

$TARGET "$@"