_ewt_regularise_job_script() {
  # NOTE: "regularised" means "*(directive lines) ?(empty line) +(code lines)"
  # NOTE: This implicitly ignores user-specified shebangs.
  local cnt=0 code_hit
  read -t 1 || return 3
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

_ewt_consolidate_var_directives() {
  # NB: Assumes that it's reading a regularised script.
  # FIXME: Does not check duplicates or distinquish assignments vs. names only.
  local -a var_directives
  read -t 0 || return 3
  while read -r || return 4 && [[ -n $REPLY ]]; do
    [[ $REPLY == '#PBS -v '+ ]] && var_directives+=("$REPLY") || echo "$REPLY"
  done
  ((${#var_directives[@]})) && {
    echo -n "${var_directives[0]}"
    unset "export_vars[0]"
    for var_list in "${var_directives[@]#*v }"; do
      echo -n ", $var_list"
    done
    echo
  }
  echo
  read -t 0 && cat || return 5
}
