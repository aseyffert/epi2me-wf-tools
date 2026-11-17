# Displays TSV files with spurious spaces correctly in less (e.g., trace.txt).
tless() {
  # Guards against blocking call to column; fails like less does with no file.
  (($# == 0)) && [[ -t 0 ]] && {
    echo >&2 'Missing filename ("tless --help" for help)'
    return 1
  }

  # column reads from stdin when passed no args; i.e., when "$@" is empty.
  column -ts $'\t', "$@" | less -S
}
