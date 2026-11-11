constrain_paths() {
  local opt OPTIND quiet {pathy,check,constraint,fail}_var var_pass
  local -a {check,constraint,fail}_vars
  while getopts 'qh' opt; do
    case $opt in
    'q') quiet=1 ;;
    'h')
      echo "Checks that each pathy var listed in PATHY_VARS_TO_CONSTRAIN"
      echo -e "\tis on a path stored in one of the PATHY_CONSTRAINT vars."
      echo "Usage:"
      echo -en "\tconstrain_paths [-q] [-h] PATHY_VARS_TO_CONSTRAIN "
      echo "PATHY_CONSTRAINT [PATHY_CONSTRAINT...]"
      echo "where:"
      echo -en "\t- PATHY_VARS_TO_CONSTRAIN is an array-readable list of names "
      echo "of pathy vars"
      echo -e "\t- each PATHY_CONSTRAINT names a pathy constraint var"
      return 0
      ;;
    *)
      echo >&2 "ERROR: Unrecognised option to constrain_paths(); -h for usage."
      return 2
      ;;
    esac
  done
  shift $((OPTIND - 1))
  read -ra check_vars <<<"$1"
  shift
  read -ra constraint_vars <<<"$@"
  ((${#check_vars[@]} * ${#constraint_vars[@]})) || return
  for pathy_var in "${check_vars[@]}" "${constraint_vars[@]}"; do
    [[ ${!pathy_var} == /* ]] || {
      ((quiet)) || echo >&2 "ERROR: $pathy_var not an absolute path."
      return 3
    }
  done
  for constraint_var in "${constraint_vars[@]}"; do
    [[ -d ${!constraint_var} ]] || {
      ((quiet)) || echo >&2 "ERROR: $constraint_var not a directory."
      return 4
    }
  done
  for check_var in "${check_vars[@]}"; do
    for constraint_var in "${constraint_vars[@]}"; do
      [[ ${!check_var} == ${!constraint_var}/* ]] && var_pass=1 && break
    done
    ((var_pass)) || fail_vars+=("$check_var")
    unset var_pass
  done
  ((${#fail_vars[@]} == 0)) || {
    ((quiet)) || echo >&2 "ERROR: (Some) pathy variables not on allowed paths:"
    ((quiet)) || echo >&2 "Variables (and current targets):"
    for fail_var in "${fail_vars[@]}"; do
      ((quiet)) || echo -e "\t$fail_var = ${!fail_var}" >&2
    done
    ((quiet)) || echo >&2 "Allowed paths:"
    for constraint_var in "${constraint_vars[@]}"; do
      ((quiet)) || echo -e "\t${!constraint_var}/*" >&2
    done
    return 5
  }
}
