#!/usr/bin/env bash

#####################################################################
# Used to build from Xcode or another build system.
#####################################################################

if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
  exit 128
fi

cd "$PROJECT_DIR/Balthisar Tidy Help Project/"
rvm use default
bundle exec middleman all
