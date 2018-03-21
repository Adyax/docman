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

POSITIONAL=()
BRANCH="master"
NEXT=0
SKIP=0

if [[ $# == 0 ]]; then
    POSITIONAL+=("-h")
    set -- "${POSITIONAL[@]}" # restore positional parameters
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -b|--branch*)
            if [[ $key == "-b" ]] || [[ $key == "--branch" ]]; then
                BRANCH="$2"
                shift # past argument
                shift # past value
            else
                BRANCH="${1#*=}"
                shift # past argument=value
            fi
        ;;
        -n|--next)
            NEXT=1
            shift # past argument
        ;;
        -s|--skip)
            SKIP=1
            shift # past argument
        ;;
        -h|--help)
            echo "Usage: -[hbns] [state] [next] [skip]"
            echo -e "\t-h, --help\n\t\tShow this help message."
            echo -e "\t-b [branch], --branch [branch], --branch=[branch]\n\t\tTag specific branch."
            echo -e "\t-n, --next\n\t\tSet next release without prompt."
            echo -e "\t-s, --skip\n\t\tSkip CI trigger with commit message."
            exit 0
        ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $NEXT == 0 ]] && [ -n "$2" ] && [ "$2" == "next" ]; then
    NEXT=1
fi

if [[ $SKIP == 0 ]] && [ -n "$3" ] && [ "$3" == "skip" ]; then
    SKIP=1
fi

git fetch
git checkout $BRANCH
git pull origin $BRANCH 2>/dev/null 

if [ -f VERSION ]; then
    BASE_STRING=`cat VERSION`
    if [[ $BASE_STRING =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)([\.\-][0-9a-zA_Z_\-]+)?$ ]]; then
        V_MAJOR=${BASH_REMATCH[1]}
        V_MINOR=${BASH_REMATCH[2]}
        V_PATCH=${BASH_REMATCH[3]}
        V_SUFFIX=${BASH_REMATCH[4]}
        echo "Current version : $BASE_STRING"
        V_PATCH=$((V_PATCH + 1))
        SUGGESTED_VERSION="${V_PREFIX}${V_MAJOR}.${V_MINOR}.${V_PATCH}${V_SUFFIX}"
    else
        if [[ $BASE_STRING =~ ^([0-9a-zA_Z_\-]+[\-])([0-9]+)\.([0-9]+)\.([0-9]+)([\.\-][0-9a-zA_Z_\-]+)?$ ]]; then
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

    if [ -n "$SUGGESTED_VERSION" ]; then
        if [[ $NEXT == 1 ]]; then
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
    git push origin $BRANCH
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
        git push origin $BRANCH
    fi
    TAG="0.1.0"
fi

if [ -n "$1" ]; then
  git fetch
  STATE_BRANCH="state_$1"
  #git show-ref --verify --quiet "refs/heads/${BRANCH}"
  git ls-remote --exit-code . origin/state_stable &> /dev/null
  if [ $? == 0 ]; then
    git checkout ${STATE_BRANCH}
    git pull origin ${STATE_BRANCH}
  else
    git checkout --orphan ${STATE_BRANCH}
    git rm --cached -r .
    git clean -f -d
  fi
  echo "type: tag" > info.yaml
  echo "version: $TAG" >> info.yaml
  git add info.yaml
  if [[ $SKIP == 1 ]]; then
    git commit -m "[skip] [ci-skip] [ci skip] Changed tag to: $TAG"
    git push -u origin ${STATE_BRANCH}
  else
    git commit -m "Changed tag to: $TAG"
    git push -u origin ${STATE_BRANCH}
  fi
  git checkout $BRANCH
  echo ${TAG}
fi
