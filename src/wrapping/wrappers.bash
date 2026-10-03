_w_shebang() {
  read -rt 1 || return 3
  [[ $REPLY != '#!'* ]] && echo '#!/usr/bin/env bash'
  echo "$REPLY"
  read -t 0 && cat || return 4
}
