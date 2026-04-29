# Setup script for epi2me-wf-tools.
#
# Handles all the steps necessary for a new user to use epi2me-wf-tools; it
#   will grow as epi2me-wf-tools grows.
#
# Currently planned responsibilities:
# For users:
#  - Create $NXF_HOME and $NXF_SINGULARITY_CACHEDIR
#  - [optional] Patch .bashrc such that $EWT_HOME/bash.env is sourced at login.

source $(dirname $(realpath $0))/bash.env
