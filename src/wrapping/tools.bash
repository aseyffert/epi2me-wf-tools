_ewt_regularise_job_script() {
  # NOTE: "regularised" means "*(directive lines) ?(empty line) +(code lines)"
  # NOTE: Trailing whitespace is stripped since we use echo.
  # NOTE: This implicitly ignores user-specified shebangs.
  local cnt=0 code_hit
  read -t 0 || return 3
  while
    ((cnt++))
    read -r
  do
    ! ((code_hit)) && [[ $REPLY != @(#*|*([[:space:]])) ]] && {
      echo
      code_hit=1
    }
    ((code_hit)) && [[ $REPLY == '#PBS '* ]] && {
      echo >&2 "WARNING: Ignored directive; (input) line $cnt."
    }
    ((code_hit)) || [[ $REPLY == '#PBS '* ]] && echo "$REPLY"
  done
  # This check covers the case where the last input line is a directive line.
  ((code_hit)) || return 4
}

_ewt_cat_directives() {
  # NB: Assumes that it's reading a regularised script.
  read -t 0 || return 3
  while read -r || return 4; do
    echo "$REPLY"
    [[ -z $REPLY ]] && return
  done
}

_ewt_consolidate_variable_lists() {
  # NB: Assumes that it's reading a regularised script.
  # NOTE:   This function doesn't check for duplicated variable list entries,
  #           primarily because doing so is quite difficult since variables in
  #           the list can themselves contain commas.
  local export_env vars_line
  read -t 0 || return 3
  until read -r || return 4 && [[ -z $REPLY ]]; do
    [[ $REPLY == '#PBS -V' ]] && export_env=1 && continue
    [[ $REPLY == '#PBS -v '* ]] && {
      [[ -z $vars_line ]] && vars_line=$REPLY || vars_line+=", ${REPLY:8}"
      continue
    }
    echo "$REPLY"
  done
  ((export_env)) && echo '#PBS -V'
  [[ -n $vars_line ]] && echo "$vars_line"
  echo
  read -t 0 && cat || return 5
}
