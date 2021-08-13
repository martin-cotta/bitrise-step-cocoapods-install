#!/bin/bash
#
# Install iOS dependencies (Homebrew, RubyGems & Cococapods).
set -e

readonly THIS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$THIS_SCRIPT_DIR/functions.sh"

#######################################
# Install homebrew dependencies
# specified as step input
#######################################
function brew_install {
  set -x
  brew install $brew_packages
  { set +x; } 2>/dev/null
  echo

  local cellar="$(brew --cellar)"
  local array=($brew_packages)

  for package in ${array[@]}; do
    add_to_cache "${cellar}/${package}"
    add_to_cache "/usr/local/opt/${package}"
  done
}

#######################################
# Install RubyGems dependencies 
# specified in the Gemfile
#######################################
function bundle_install {
  cd "${source_root_path}"

  local current=$(bundler --version | tr -cd "[:digit:]\.")
  local bundled=$(get_bundler_version)

  echo
  echo "Current bundler: $current"
  echo "Expected bundler: $bundled"
  echo

  if [ "${bundled}" != "${current}" ]; then
    set -x
    gem install bundler -v ${bundled} --no-document --force
    { set +x; } 2>/dev/null
    echo
  fi

  set -x
  bundle _${bundled}_ check || bundle _${bundled}_ install --jobs 20 --retry 5 --path ${source_root_path}/vendor/bundle
  { set +x; } 2>/dev/null
  echo

  add_to_cache "${source_root_path}/vendor -> ${source_root_path}/Gemfile.lock"
}

#######################################
# Install CocoaPods dependencies
# specified in the Podfile
#######################################
function pod_install {
  local version=$(get_bundler_version)

  cd "${source_root_path}"
  set -x
  bundle _${version}_ exec pod install --no-repo-update --deployment
  { set +x; } 2>/dev/null
  echo

  add_to_cache "${source_root_path}/Pods -> ${source_root_path}/Podfile.lock"
  add_to_cache "~/.cocoapods/repos/nerdwallet -> ${source_root_path}/Podfile.lock"
}

#######################################
# main
#######################################
print_config
validate_inputs
brew_install
bundle_install
pod_install
update_cache
print_output
