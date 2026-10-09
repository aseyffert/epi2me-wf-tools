#!/usr/bin/env bash

parse_qstat_cleanup() {
  unset -v default__ignored_stats
  unset -v name_spec stats_line kv_pair{,s} key VAL staging _cache
  unset -f {user,group}_grants_access _evaporate_pbs_generic parse_val
}

user_grants_access() {
  local user_spec blanket_access
  for user_spec in ${VAL//,/ }; do
    case $user_spec in
    "$USER") return ;;
    "-$USER") return 1 ;;
    '+') blanket_access=1 ;;
    esac
  done
  ((blanket_access))
}

group_grants_access() {
  local user_groups grp
  user_groups="$(id -Gn)"
  for grp in ${VAL//,/ }; do
    [[ " $user_groups " == *" $grp "* ]] && return
  done
}

_evaporate_pbs_generic() {
  # NOTE: Assumes that there's only one specification in the [...] spec.
  VAL=${VAL//[^0-9]/}
}

parse_val() {
  case $VAL in
  *u:PBS_GENERIC*) _evaporate_pbs_generic ;;
  esac
}
default__ignored_stats=(
  queue_type enabled max_run_res.ncpus acl_{user,group}_enable
  {resources_{min,max},default_chunk}.nodetype
  resources_assigned.{mem,mpiprocs,ncpus,nodect}
)
[[ -v IGNORED_STATS ]] || export IGNORED_STATS=("${default__ignored_stats[@]}")

declare -xA QUEUE_STATS
declare -A _cache=(['ignored_stats']=${IGNORED_STATS[*]})

while IFS='|' read -r name_spec stats_line; do
  qname=${name_spec#* }
  unset -v kv_pairs staging
  declare -A staging
  IFS='|' read -ra kv_pairs <<<"$stats_line"
  for kv_pair in "${kv_pairs[@]}"; do
    unset -v key VAL
    IFS='=' read -r key VAL <<<"$kv_pair"
    [[ " ${_cache['ignored_stats']} " == *" $key "* ]] && continue
    case $key in
    'acl_users') user_grants_access || continue 2 ;;
    'acl_groups') group_grants_access || continue 2 ;;
    esac
    parse_val
    staging[$key]=$VAL
  done
  for key in "${!staging[@]}"; do
    QUEUE_STATS["$qname:$key"]=${staging[$key]}
  done
done < <(qstat -QfF dsv)
