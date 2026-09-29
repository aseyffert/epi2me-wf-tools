_ewt_regularise_job_script() {
  # NOTE: "regularised" means "*(directive lines) ?(empty line) +(code lines)"
  # NOTE: This implicitly ignores user-specified shebangs.
  local cnt=0 line code_hit
  read -t 0 || return 3
  while
    ((cnt++))
    read -r line
  do
    ! ((code_hit)) && [[ $line != @(#*|*([[:space:]])) ]] && {
      echo
      code_hit=1
    }
    ((code_hit)) && [[ $line == '#PBS '* ]] && {
      echo >&2 "WARNING: Ignored directive; (input) line $cnt."
    }
    ((code_hit)) || [[ $line == '#PBS '* ]] && echo "$line"
  done
  # This check covers the case where the last input line is a directive line.
  ((code_hit)) || return 4
}

_ewt_cat_directives() {
  # NB: Assumes that it's reading a regularised script.
  local line
  read -t 0 || return 3
  while read -r line || return 4; do
    echo "$line"
    [[ -z $line ]] && return
  done
}

_ewt_consolidate_var_directives() {
  # NB: Assumes that it's reading a regularised script.
  # FIXME: Does not check duplicates or distinquish assignments vs. names only.
  local line
  local -a var_directives
  read -t 0 || return 3
  while read -r line || return 4 && [[ -n $line ]]; do
    [[ $line == '#PBS -v '+ ]] && var_directives+=("$line") || echo "$line"
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
