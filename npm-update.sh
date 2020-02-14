#!/usr/bin/env bash

NPM_UPDATE_DEFAULT_PACKAGE_FILE=package.json
NPM_UPDATE_PACKAGE_FILE=$NPM_UPDATE_DEFAULT_PACKAGE_FILE

usage() {
cat<<EOF
Update outdated npm packages to the latest available

$(basename "$0")
  -p|--package  Name of package file (default: $NPM_UPDATE_PACKAGE_FILE)
  -d|--dry-run  Only echo commands; do not execute them
  -h|--help     Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--package)
      NPM_UPDATE_PACKAGE_FILE="$2"
      shift 2
      ;;
    -d|--dry-run)
      NPM_UPDATE_DRY_RUN=1
      shift
      ;;
    -h|--help|-?)
      usage
      exit 0
      ;;
  esac
done

set -e

npm install

prod=
dev=
for it in $(npm outdated | tail -n +2 | awk '{print $1, $4}' | sed 's/ /;/g'); do
  arr=(${it//;/ })
  component=${arr[0]}
  version=${arr[1]}
  cv="$component@$version"
  if cat "$NPM_UPDATE_PACKAGE_FILE" | docker run --rm -i stedolan/jq .devDependencies | grep -q "\"$component\""; then
    dev="$dev $cv"
    echo " dev: $cv"
  else
    prod="$prod $cv"
    echo "prod: $cv"
  fi
done

if [ -n "$prod" ]; then
  prod="npm install --save $prod"
  echo $prod
  if [ -z "$NPM_UPDATE_DRY_RUN" ]; then
    $prod
  fi
fi

if [ -n "$dev" ]; then
  dev="npm install --save-dev $dev"
  echo $dev
  if [ -z "$NPM_UPDATE_DRY_RUN" ]; then
    $dev
  fi
fi