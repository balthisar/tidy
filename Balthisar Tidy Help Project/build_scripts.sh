#!/bin/bash

################################################################################
# GNU make rather sucks when there are spaces in pathnames, as is common on
# modern operating systems, so we will build help with a shell script instead.
# When make works, it speeds things up by not building things that aren't
# needed, but middleman builds are all or nothing, so we only have to make sure
# it's up to date to avoid building.
################################################################################


#==========================================================
# Functions
#==========================================================

# Simplifies the heredoc.
function print_env {
  echo $([ -z "${1}" ] && echo "--empty-- (will abort)" || echo "${1}")
}


#==========================================================
# Verify the Environment
#==========================================================

MM_EXISTS=$([[ -s "${HOME}/.rvm/environments/default" ]] && source "${HOME}/.rvm/environments/default" && which middlemac)

cat <<-HEREDOC

Build Balthisar Tidy Help
-------------------------
This script builds the Balthisar Tidy Help Project selectively for Balthisar Tidy.

It's intended to be run from within Xcode, which will build using XCBBuildService. In
this way, the proper environment variables are supplied automatically. In order to
execute this script from the terminal, you must populate these variables yourself.

       Script run from: $(basename -- $(ps -o comm= $PPID))
         CONFIGURATION: $(print_env "${CONFIGURATION}")
           PROJECT_DIR: $(print_env "${PROJECT_DIR}")
    BUILT_PRODUCTS_DIR: $(print_env "${BUILT_PRODUCTS_DIR}")
         Middlemac Gem: $(print_env "${MM_EXISTS}")
HEREDOC

[ -n "${CONFIGURATION}" ] && [ -n "${PROJECT_DIR}" ] && [ -n "${BUILT_PRODUCTS_DIR}" ] && [ -n "${MM_EXISTS}" ] || exit 1


#==========================================================
# Inform the user. We're just going to assume that the
# source exists, and that we have a proper target, else
# things have gone really wrong.
#==========================================================

HB_TARGET="${CONFIGURATION:0:3}"
HB_SOURCE="${PROJECT_DIR}/Balthisar Tidy Help Project"
HB_OUTPUT="${BUILT_PRODUCTS_DIR}/Balthisar Tidy.help"

cat <<-HEREDOC
             HB_TARGET: ${HB_TARGET}
             HB_SOURCE: ${HB_SOURCE}
             HB_OUTPUT: ${HB_OUTPUT}
      Helpbook Version: ${TIDY_CFBundleShortVersionString}
                  Date: $(date)

HEREDOC


#==========================================================
# Check source and build dates. Directories should reflect 
# modification times for deleted files. 
#==========================================================

if [ -d "${HB_OUTPUT}" ]; then

  NEWER_LIST=$(find "${HB_SOURCE}" -newer "${HB_OUTPUT}" -print)

  if [ -n "${NEWER_LIST}" ]; then
    echo "The Helpbook will be built because the following files are newer:"
    echo "${NEWER_LIST}"
  else
    echo "The Helpbook is already up to date, and will not be built."
    exit 0
  fi

else
  echo "The Helpbook will be built because the Helpbook is not present."
fi


#==========================================================
# Build the Helpbook
#==========================================================

export LANG=en_US.UTF-8
source "${HOME}/.rvm/environments/default"

# Output directory is set in the config.rb file, and will be the
# correct directory in DerivedData. The name of the .help file
# is set by middlemac based on the CFBundlename.
bundle exec middleman build --verbose --target "${HB_TARGET}"

if [ "$?" -ne 0 ]; then
  echo "error: Middlemac did not execute successfully."
  exit 1
fi

touch "${HB_OUTPUT}"

