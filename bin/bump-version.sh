#!/bin/bash
 
# works with a file called VERSION in the current directory,
# the contents of which should be a semantic version number
# such as "1.2.3"
 
# this script will display the current version, automatically
# suggest a "minor" version update, and ask for input to use
# the suggestion, or a newly entered value.
 
# once the new version number is determined, the script will
# pull a list of changes from git history, prepend this to
# a file called CHANGES (under the title of the new version
# number) and create a GIT tag.

git checkout master
git pull origin master
git fetch

if [ -f VERSION ]; then
    BASE_STRING=`cat VERSION`
    BASE_LIST=(`echo $BASE_STRING | tr '.' ' '`)
    V_MAJOR=${BASE_LIST[0]}
    V_MINOR=${BASE_LIST[1]}
    V_PATCH=${BASE_LIST[2]}
    echo "Current version : $BASE_STRING"
    #V_MINOR=$((V_MINOR + 1))
    V_PATCH=$((V_PATCH + 1))
    #V_PATCH=0
    SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"

    if [ -n "$2" ] && [ "$2" == "next" ]; then
        INPUT_STRING=$SUGGESTED_VERSION
    else
      read -p "Enter a version number [$SUGGESTED_VERSION]: " INPUT_STRING
      if [ "$INPUT_STRING" = "" ]; then
          INPUT_STRING=$SUGGESTED_VERSION
      fi
    fi

    echo "Will set new version to be $INPUT_STRING"
    echo $INPUT_STRING > VERSION
    TAG=${INPUT_STRING}
    echo "Version $INPUT_STRING:" > tmpfile
    git log --pretty=format:" - %s" "$BASE_STRING"...HEAD >> tmpfile
    echo "" >> tmpfile
    echo "" >> tmpfile
    cat CHANGES >> tmpfile
    mv tmpfile CHANGES
    git add CHANGES VERSION
    git commit -m "[skip] [ci-skip] [ci skip] Version bump to $INPUT_STRING"
    git tag -a -m "[skip] [ci-skip] [ci skip] Tagging version $INPUT_STRING" "$INPUT_STRING"
    git push origin ${INPUT_STRING}
    git push origin master
else
    echo "Could not find a VERSION file"
    read -p "Do you want to create a version file and start from scratch? [y]" RESPONSE
    if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "y" ]; then
        echo "0.1.0" > VERSION
        echo "Version 0.1.0" > CHANGES
        git log --pretty=format:" - %s" >> CHANGES
        echo "" >> CHANGES
        echo "" >> CHANGES
        git add VERSION CHANGES
        git commit -m "[skip] [ci-skip] [ci skip] Added VERSION and CHANGES files, Version bump to 0.1.0"
        git tag -a -m "[skip] [ci-skip] [ci skip] Tagging version 0.1.0" "0.1.0"
        git push origin --tags
        git push origin master
    fi
    TAG="0.1.0"
fi

if [ -n "$1" ]; then
  git fetch
  BRANCH="state_$1"
  #git show-ref --verify --quiet "refs/heads/${BRANCH}"
  git ls-remote --exit-code . origin/state_stable &> /dev/null
  if [ $? == 0 ]; then
    git checkout ${BRANCH}
    git pull origin ${BRANCH}
  else
    git checkout --orphan ${BRANCH}
    git rm --cached -r .
    git clean -f -d
  fi
  echo "type: tag" > info.yaml
  echo "version: $TAG" >> info.yaml
  git add info.yaml
  if [ -n "$3" ] && [ "$3" == "skip" ]; then
    git commit -m "[skip] [ci-skip] [ci skip] Changed tag to: $TAG" & git push -u origin ${BRANCH}
  else
    git commit -m "Changed tag to: $TAG"
    git push -u origin ${BRANCH}
  fi
  git checkout master
  echo ${TAG}
fi
