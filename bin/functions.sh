#!/bin/bash

#
# Check if git directory has no changes.
#
dm_is_clean () {
    ${git} rev-parse --verify HEAD >/dev/null || echo 1
    ${git} update-index -q --ignore-submodules --refresh
    err=0

    if ! ${git} diff-files --quiet --ignore-submodules
    then
        err=1
    fi

    if ! ${git} diff-index --cached --quiet --ignore-submodules HEAD --
    then
        err=1
    fi

    test -z "$(git status --porcelain)" || err=1

    if [ $err = 1 ]
    then
        echo $err
    fi
}

#
# Git subtree add/pull depending on dir existance. 
#
dm_git_subtree_pull () {
  if [ ! -d "$1" ]; then
    dm_debug "Subtree add $1 $2 $3"
    ${git} subtree add --squash --prefix=$1 $2 $3
  else
    dm_debug "Subtree pull $1 $2 $3"
    ${git} subtree pull --squash --prefix=$1 $2 $3 -m "Subtree pull $1 $2 $3"
  fi
}

#
# Git subtree add/pull depending on dir existance.
#
dm_git_get () {
  _version=${3:-master}
  _target=${4:-branch}
  if [ ! -d "$2" ]; then
    dm_debug "Local repository not exists: $1 $2"
    ${git} clone $1 $2
    cd $2
    ${git} checkout $3

  else
    cd $2
    dm_debug "Local repository exists: $1 $2"
    if [[ "$_target" == 'branch' ]]; then
      ${git} pull origin $3
    elif [[ "$_target" == 'tag' ]]; then
      echo $4
      ${git} checkout $3
    fi
  fi
}

#
# Git get version (branch or tag).
#
dm_git_checkout_and_copy () {
  _DIR=${WORKSPACE}/attic/$1
  mkdir -p $_DIR
  if [[ ! -d "$_DIR/$3/$4" ]]; then
    ${git} clone $2 $_DIR/$3/$4
    cd $_DIR/$3/$4
    ${git} checkout $4
  else
    cd $_DIR/$3/$4
    if [[ "$3" == 'branch' ]]; then
      ${git} pull origin $4
    elif [[ "$3" == 'tag' ]]; then
      echo $4
      ${git} checkout $4
    fi
  fi

  rm -fR $5
  mkdir -p $5
  # We don't need .git here.
  rm -fR $_DIR/$3/$4/.git
  cp -fR $_DIR/$3/$4/. $5/
  rm -fR $_DIR/$3/$4/
}

dm_find_repo_dir_by_name () {
  basename="$(basename "${1}")"
  needle="$(basename "${2}")"
  if [[ $basename == "$needle" ]]; then
    echo $1
    return
  fi

  for dirname in $1/*; do
    [ -d "$dirname" ] || continue # if not a directory, skip
    dm_find_repo_dir_by_name $dirname $2
  done
}

dm_get_repo_state_config () {
  repo_dir=$(dm_find_repo_dir_by_name $1 $2)
  if [ -d "$repo_dir/_states" ]; then
    dm_read_properties_file $repo_dir/_states/${3}.properties $4
  else
    echo "No state dir"
    exit 1
  fi 
}

dm_write_properties_file_value () {
  sed -i '' "s/^\($2\s*=\s*\).*\$/\1$3/" $1
}

dm_set_repo_state_config () {
  repo_dir=$(dm_find_repo_dir_by_name $1 $2)
  if [ -d "$repo_dir/_states" ]; then
    dm_write_properties_file_value $repo_dir/_states/${3}.properties VERSION_TYPE $4
    dm_write_properties_file_value $repo_dir/_states/${3}.properties VERSION $5
  else
    echo "No state dir"
    exit 1
  fi 

  cd "$repo_dir"
  ${git} add -A
  ${git} commit -m "Updated $2 $3 to $4-$5"
  ${git} push origin master
}

dm_build_recursive () {
  # Skip if no info.properties file.
  [ -f "${1}/info.properties" ] || return

  dm_read_properties_file ${1}/info.properties

  BUILD_DIR_NAME="$(basename "${2}")"
  BUILD_DIR="$2"
  ITEM_TYPE_PARAM="target_${_type}_deploy_as"
  ITEM_TYPE=${!ITEM_TYPE_PARAM}

  dm_read_properties_file $1/_states/${_DM_BUILD_STATE}.properties
  echo "Install into $BUILD_DIR, Type: $ITEM_TYPE, Version: $VERSION_TYPE-$VERSION"

  if [[ $ITEM_TYPE == "repo" ]]; then
    dm_git_get ${repo} $BUILD_DIR $VERSION $VERSION_TYPE
    ROOT_REPO_DIR="$BUILD_DIR"
  fi

  if [[ $ITEM_TYPE == "dir" ]]; then
    mkdir -p $BUILD_DIR
  fi

  if [[ $ITEM_TYPE == "copy_strip_git" ]]; then
    cd $ROOT_REPO_DIR
    #dm_git_subtree_pull $_subtree_prefix $repo $VERSION
    dm_git_checkout_and_copy $_subtree_prefix $repo $VERSION_TYPE $VERSION $BUILD_DIR
  fi

  if [[ $ITEM_TYPE == "drupal" ]]; then
    dm_debug "Install Drupal"
    # Build docroot dir.
    if [ -f "$BUILD_DIR/modules/system/system.info" ]; then
      INSTALLED_DRUPAL_VERSION=$(grep "version = \"" $BUILD_DIR/modules/system/system.info | awk -F\" '{print $2}')
    fi

    # Install Drupal.
    mkdir -p $BUILD_DIR
    if [[ ! "$INSTALLED_DRUPAL_VERSION" == "$VERSION" ]] || [[ "$_FORCE" == "1" ]]
    then
      TEMP_DRUPAL_DIR=`mktemp -d -t 'drupal'`
      mkdir -p $TEMP_DRUPAL_DIR
      if [ ! -d "$TEMP_DRUPAL_DIR/drupal-${VERSION}" ] || [[ "$_FORCE" == "1" ]]
      then
        cd $TEMP_DRUPAL_DIR
        drush dl drupal-${VERSION} --yes
        rm -fR drupal-${VERSION}/sites
      fi

      rm -fR $BUILD_DIR
      mkdir -p $BUILD_DIR
      cp -fR $TEMP_DRUPAL_DIR/drupal-${VERSION}/. $BUILD_DIR
      #rm -fR ${WORKSPACE}/drupal/drupal-${VERSION}
    else
      echo "Drupal already installed."
    fi
  fi

  cd $BUILD_DIR
  for dirname in $1/*; do
    [ -d "$dirname" ] || continue # if not a directory, skip
    basename="$(basename "${dirname}")"
    dm_build_recursive $dirname $2/$basename
  done
}

#
# Git commit if there are changes in dir.
#
dm_git_commit_if_changes () {
  repo_clean=$(dm_is_clean)
  if [ "$repo_clean" == "1" ]
  then
    #${git} merge --ff-only
    ${git} add --all $1
    ${git} commit -m "$2"
    changed=1
  fi
}

#
# Git subtree add/pull depending on dir existance.
#
dm_debug () {
  if [ "$_DEBUG" == "1" ]; then
    echo 1>&2 "$@"
  fi
}

dm_read_properties_file () {
  dm_debug "Read properties: $1 $2"
  TEMPFILE=`mktemp 2>/dev/null || mktemp -t 'tmp'`
  cat $1 |
  if [ "$(uname)" == "Darwin" ]
  then
    sed -Ee 's/"/"/'g|sed -Ee "s/(.*)=(.*)/$2\1=\"\2\"/g">$TEMPFILE
  else  
    sed -re 's/"/"/'g|sed -re "s/(.*)=(.*)/$2\1=\"\2\"/g">$TEMPFILE
  fi
  source $TEMPFILE
  rm $TEMPFILE
}

#
# Send message to slack.
#
dm_slack_send () {
  slack_message_fallback="$1"
  slack_message_text="$1"
  slack_message_pretext=""

  if [ "$enable_slack_notification" == "1" ]
  then
    if [ -n "$2" ]
    then
    slack_message_color="$2"
    attachments="\"attachments\": [{\"fallback\": \"${slack_message_fallback}\", \"text\": \"${slack_message_text}\", \"pretext\": \"${slack_message_pretext}\", \"color\": \"${slack_message_color}\", \"fields\": [ 
        { \"title\": \"Project\", \"value\": \"${project}\", \"short\": true },
        { \"title\": \"Environment\", \"value\": \"prod\", \"short\": true }
      ]}],"
    else 
      attachments=""  
    fi  

    curl -X POST --data-urlencode "payload={\"channel\": \"#${slack_channel}\", $attachments \"username\": \"${slack_username}\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" ${slack_address}?token=${slack_token}
  fi  
}

