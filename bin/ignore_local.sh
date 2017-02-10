#!/usr/bin/env bash
set -vx

# Add following files into local git ignore only
if [ "$1" == "local" ]; then
  if [ -f .git/info/exclude ]; then
    rm .git/info/exclude
  fi
  echo "info.yaml" > .git/info/exclude
  ls -al
  git update-index --assume-unchanged info.yaml
fi

set +vx
