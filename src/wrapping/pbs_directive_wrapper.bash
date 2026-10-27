(($# % 2)) && return 3

while read -r var && read -r val; do
  [[ $var == -? ]]
  echo "#PBS $var $val"
done <<<"$*"
