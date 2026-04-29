# Setup script for epi2me-wf-tools.
#
# Handles all the steps necessary for a new user to use epi2me-wf-tools; it
#   will grow as epi2me-wf-tools grows.
#
# Currently planned responsibilities:
# For users:
#  - Create $NXF_HOME and $NXF_SINGULARITY_CACHEDIR
#  - [optional] Patch .bashrc such that $EWT_HOME/bash.env is sourced at login.

if [[ $BASH_SOURCE != $0 ]]; then
  echo >&2 "ERROR: $BASH_SOURCE was sourced; must be executed."
  return 1
fi

source $(dirname $(realpath $0))/bash.env

for var_name in NXF_HOME NXF_SINGULARITY_CACHEDIR; do
  if ! [[ ${!var_name} == /* ]]; then
    echo >&2 "ERROR: $0 expects an absolute path for ${var_name}."
    exit 1
  fi
  if ! [[ ${!var_name} == $USER_LUSTRE/* ]]; then
    echo >&2 "ERROR: Bad $var_name; must be in ${USER_LUSTRE}."
    exit 2
  fi
done
mkdir -p "$NXF_HOME" "$NXF_SINGULARITY_CACHEDIR"
