#!/bin/sh

#
# Check if git directory has no changes.
#
cd $1

git rev-parse --verify HEAD >/dev/null || echo 1
git update-index -q --ignore-submodules --refresh

err=0

if ! git diff-files --quiet --ignore-submodules
then
  err=1
fi

if ! git diff-index --cached --quiet --ignore-submodules HEAD --
then
  err=1
fi

test -z "$(git status --porcelain)" || err=1

if [ ${err} = "1" ]
then
  echo ${err}
  exit 1
fi
