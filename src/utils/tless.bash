# Renders TSV (and CSV) files with spurious spaces sensibly via less.
tless() {
  [[ $1 == @(-h|--help) ]] && {
    # NOTE: The block below contains literal TABs.
    cat <<-EOF
			A utility function that renders TSV files nicely via less.

			Usage:
			  tless [-h|--help] [<file>...]

			Options:
			  -h, --help: Print this help message.

			Arguments:
			  file: A TSV or CSV file. (See "man column" for multiple files.)

			If no file is provided, tless reads from stdin; if one is, stdin is ignored.
		EOF
    return
  }

  # Guards against blocking call to column; fails like less does with no file.
  (($# == 0)) && [[ -t 0 ]] && {
    echo >&2 'Missing filename ("tless --help" for help)'
    return 1
  }

  # column reads from stdin when passed no args; i.e., when "$@" is empty.
  column -ts $'\t', "$@" | less -S
}
