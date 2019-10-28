#!/usr/bin/env bash

############################################################
# Use this shell script instead of `carthage` when setting
# up dependencies!
#
# By default, Carthage uses projects' default build system
# to build frameworks, which is a reasonable proposition
# in most cases. However, Xcode doesn't allow us to silence
# warnings in frameworks, so we'll pass some extra build
# flags to Carthage via XCODE_XCCONFIG_FILE.
#
# This script can be used with Carthage's `bootstrap`,
# `build`, and `update` commands.
############################################################


#---------------------------------------------------
# help()
#---------------------------------------------------
help()
{
cat <<-HEREDOC

`basename $0` help
----------------
Use this shell script instead of the 'carthage' command directly in order to
set some of the build flags in the frameworks prior to building them. This
provides the following benefits:

  - We can silence warnings in the frameworks, because they are noisy and
    distract us from fixing our own warnings.

  - We can commonize some of the deployment targets in the imported frameworks,
    which also cause warnings.

To use, simply substitute this shell script for the carthage command, using all
of the same command line arguments, such as bootstrap, build, or update. Note
that we will necessarily build frameworks, so this script will automatically
add '--no-use-binaries'.

HEREDOC

if command -v carthage &> /dev/null; then
    carthage help
fi

exit 0
}



#===================================================
# Main
#===================================================

if [ $# -eq 0 ] || [ $1 = 'help' ] || [ $1 = '-h' ] || [ $1 = '--help' ]; then
    help
    exit 1
fi

if ! command -v carthage &> /dev/null
then
    echo "You must install Carthage to use this script. Here's how to use this script once installed."
    help
    exit 1
fi


#set -euo pipefail
xcconfig=$(mktemp /tmp/balthisar-tidy-carthage.xcconfig.XXXXXX)
#trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

cat << HEREDOC >> $xcconfig
MACOSX_DEPLOYMENT_TARGET                      = 10.12
CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = NO
HEREDOC

COMMAND="carthage ${@} --no-use-binaries"

echo Temporary xcconfig file ${xcconfig} will be used, containing:
echo ~~~
cat $xcconfig
echo ~~~

export XCODE_XCCONFIG_FILE="$xcconfig"
echo ${COMMAND}
${COMMAND}
