derive_dirname() {
  local full_path
  full_path="$(realpath "$1" 2>/dev/null)" || {
    echo >&2 "ERROR: Unable to resolve realpath for $1."
    return 1
  }
  echo "${full_path%/*}"
}
