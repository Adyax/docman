#!/bin/bash

if [ -n "$1" ]; then
  git fetch
  BRANCH="$1"
  git ls-remote --exit-code . origin/${BRANCH} &> /dev/null
  if [ $? == 0 ]; then
    git checkout ${BRANCH}
    git pull origin ${BRANCH}
  else
    git checkout --orphan ${BRANCH}
    git rm --cached -r .
    git clean -f -d
  fi
  git push -u origin ${BRANCH}
fi
