# Displays TSV files with spurious spaces correctly in less (e.g., trace.txt).
tless() {
  (($# > 0))
  local got_args=$?
  [[ ! -t 0 ]]
  local piped_to=$?
  if ((got_args && piped_to)); then
    echo >&2 "ERROR: Got filename(s) while processing piped input."
    return 1
  fi
  ((got_args || piped_to)) && column -ts $'\t', "$@" | less -S
}
