w_shebang() {
  echo '#!/usr/bin/env bash'
  read -t 0 && cat || return 3
}
