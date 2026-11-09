# Displays TSV files with spurious spaces correctly in less (e.g., trace.txt).
tless() {
  local piped_to
  [[ ! -t 0 ]] && ((piped_to++))
  (($# ^ piped_to)) && column -ts $'\t', "$@" | less -S
}
