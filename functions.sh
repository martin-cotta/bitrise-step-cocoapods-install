# cache paths to be appended to BITRISE_CACHE_INCLUDE_PATHS 
CACHE=$'\n'

function add_to_cache {
  CACHE+=$1
  CACHE+=$'\n'
}

function update_cache {
  envman add --key BITRISE_CACHE_INCLUDE_PATHS --value "${BITRISE_CACHE_INCLUDE_PATHS}${CACHE}"
}

function print_config {
  echo
  echo "  Configs:"
  echo "  - Brew Packages: $brew_packages"
  echo "  - iOS Project Path: $source_root_path"
  echo
}

function print_output {
  echo
  echo " Output:"
  echo " - Paths to cache: $CACHE" | awk NF
  echo
}

function err {
  echo
  echo "❌ $*" >&2
  echo
}

# validate_required 'name' 'value'
function validate_required {
  if [ -z "$2" ]; then
    err "Missing input for: $1"
    exit 1
  fi
}

# validate_file '/dir/file.txt'
function validate_file {
  if [ ! -f "${1}" ]; then
    err "File not found: ${1}"
    exit 1
  fi
}

# validate_dir 'some/dir/path'
function validate_dir {
  if [ ! -d "${1}" ]; then
    err "Dir not found: ${1}"
    exit 1
  fi
}

function validate_inputs {
  # make path absolute if needed
  [[ $source_root_path != /* ]] && source_root_path="${BITRISE_SOURCE_DIR}/${source_root_path}"

  validate_required 'Brew packages' "${brew_packages}"
  validate_required 'iOS project root' "${source_root_path}"
  validate_dir "${source_root_path}"
  validate_file "${source_root_path}/Gemfile"
  validate_file "${source_root_path}/Podfile"
}

function get_bundler_version {
  local lock_path="${source_root_path}/Gemfile.lock"
  validate_file "$lock_path"
  tail -n 1 "$lock_path" | tr -cd "[:digit:]\."
}
