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
    echo $BASE_STRING
    if [[ $BASE_STRING =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)([\.\-][0-9a-zA_Z_\-]+)?$ ]]; then
        # echo "WO PREFIX"
        V_MAJOR=${BASH_REMATCH[1]}
        V_MINOR=${BASH_REMATCH[2]}
        V_PATCH=${BASH_REMATCH[3]}
        V_SUFFIX=${BASH_REMATCH[4]}
        echo "Current version : $BASE_STRING"
        # echo "V_MAJOR $V_MAJOR"
        # echo "V_MINOR $V_MINOR"
        # echo "V_PATCH $V_PATCH"
        # echo "V_SUFFIX $V_SUFFIX"
        V_PATCH=$((V_PATCH + 1))
        SUGGESTED_VERSION="${V_PREFIX}${V_MAJOR}.${V_MINOR}.${V_PATCH}${V_SUFFIX}"
    else
        if [[ $BASE_STRING =~ ^([0-9a-zA_Z_\-]+[\-])([0-9]+)\.([0-9]+)\.([0-9]+)([\.\-][0-9a-zA_Z_\-]+)?$ ]]; then
            # echo "W PREFIX"
            # V_PREFIX=${BASH_REMATCH[1]}
            # V_MAJOR=${BASH_REMATCH[2]}
            # V_MINOR=${BASH_REMATCH[3]}
            # V_PATCH=${BASH_REMATCH[4]}
            # V_SUFFIX=${BASH_REMATCH[5]}
            echo "V_PREFIX $V_PREFIX"
            echo "V_MAJOR $V_MAJOR"
            echo "V_MINOR $V_MINOR"
            echo "V_PATCH $V_PATCH"
            echo "V_SUFFIX $V_SUFFIX"
            echo "Current version : $BASE_STRING"
            V_PATCH=$((V_PATCH + 1))
            SUGGESTED_VERSION="${V_PREFIX}${V_MAJOR}.${V_MINOR}.${V_PATCH}${V_SUFFIX}"
        fi
    fi

    echo $SUGGESTED_VERSION


    if [ -n "$SUGGESTED_VERSION" ]; then
        if [ -n "$2" ] && [ "$2" == "next" ]; then
          INPUT_STRING=$SUGGESTED_VERSION
        else
            read -p "Enter a version number [$SUGGESTED_VERSION]: " INPUT_STRING
            if [ "$INPUT_STRING" = "" ]; then
                INPUT_STRING=$SUGGESTED_VERSION
            fi
        fi
    else
        read -p "Enter a version number: " INPUT_STRING
        if [ "$INPUT_STRING" = "" ]; then
            echo "Version number should not be empty to continue."
            exit 1
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
