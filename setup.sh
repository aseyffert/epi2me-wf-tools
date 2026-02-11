# Setup script for epi2me-wf-tools.
#
# Handles all the steps necessary for a new user to use epi2me-wf-tools; it
#  will grow as epi2me-wf-tools grows.
#
# Currently planned responsibilities:
# For users:
#  - Create ${HOME}/.singularity_cache/ (if it doesn't already exist)
#  - Check that their group ID is correct, so they can access
#    /mnt/lustre/groups/CBBI1691/
#  - Patch .bashrc such that:
#    - epi2me-wf-tools's tools are on PATH,
#    - NXF_SINGULARITY_CACHEDIR is set to ${HOME}/.singularity_cache/
#    - NXF_SINGULARITY_LIBRARYDIR is set to
#      /mnt/lustre/groups/CBBI1691/singularity_images/
