derive_dirname() {
  local OPTIND OPTARG OPTERR opt verbose=1 full_path
  # FIXME: This should likely use OPTERR to toggle verbosity (somehow)
  while getopts 'q' opt; do
    case $opt in
    q) verbose=0 ;;
    *) return 1 ;;
    esac
  done
  shift $((OPTIND - 1))
  full_path="$(realpath "$1" 2>/dev/null)" || {
    ((verbose)) && {
      echo >&2 "ERROR: Unable to resolve realpath for $1."
    }
    return 3
  }
  echo "${full_path%/*}"
}
