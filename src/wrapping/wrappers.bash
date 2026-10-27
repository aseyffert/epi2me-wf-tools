_w_shebang() {
  read -rt 1 || return 3
  [[ $REPLY != '#!'* ]] && echo '#!/usr/bin/env bash'
  echo "$REPLY"
  read -t 0 && cat || return 4
}

_w_chain() {
  [[ -n $EWT_CHAIN_WRAPPERS ]] && [[ -r $EWT_CHAIN_BASE_SCRIPT ]] || return 3
  echo '#PBS -v EWT_CHAIN_BASE_SCRIPT, EWT_CHAIN_WRAPPERS'
  read -t 0 && cat || return 4
  local -a wrappers
  read -ra wrappers <<<"$EWT_CHAIN_WRAPPERS"
  echo "_ewt_wrap_job_script $EWT_CHAIN_BASE_SCRIPT ${wrappers[*]} | qsub"
}
