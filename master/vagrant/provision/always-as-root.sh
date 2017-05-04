#!/usr/bin/env bash

#== Import script args ==

app_path=$(echo "$1")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision script: 'always-as-root.sh' user: `whoami`"

echo "Script: 'always-as-root.sh'. Done"
