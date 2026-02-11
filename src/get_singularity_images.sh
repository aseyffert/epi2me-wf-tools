#!/usr/bin/env bash
# 
# Resolves and pulls (via singularity) the container images required by a
#  epi2me-labs/wf-human-variation Nextflow workflow from hub.docker.com.
#
# Given the requirement that data transfers should be kept to a minimum on the
#  CHPC's login nodes, it's best to run the wf-human-variation workflow with
#  --offline enabled. Hence, we must manage the workflow's container images
#  ourselves.
#
# This script does this without any user intervention, but expects that:
#  - The workflow resides in $HOME/.nextflow/assets,
#  - The workflow's base.config file hasn't been altered, (*)
#  - The NXF_SINGULARITY_LIBRARYDIR environment variable is set, and
#  - The NXF_SINGULARITY_CACHEDIR environment variable is set.
#  (*) More accurately: it expects that (grep '"sha\|"ont' base.config) yields
#   what it would if base.config were unaltered.

command -v singularity || module load chpc/singularity

# TODO: Some of these should probably sourced from a central config(?)
registry_protocol='docker://'
org_name='ontresearch'
wf_assets=$HOME/.nextflow/assets/epi2me-labs/wf-human-variation
base_conf=$wf_assets/base.config
# num_imgs=10
readonly registry_protocol org_name wf_assets base_conf

readarray -t tag_lines < <(grep '"ont' $base_conf)
tag_lines=("${tag_lines[@]#*/}")
tag_lines=("${tag_lines[@]%\}\"}")
tag_lines=("${tag_lines[@]/:*wf./ }")

readarray -t sha_lines < <(grep '"sha' $base_conf)
sha_lines=("${sha_lines[@]//[\"\|=]}")

declare -A atoms
for tag_line in "${tag_lines[@]}"; do
  read -r tag key <<< "$tag_line"
  atoms[$key]=$tag
done
unset key
for sha_line in "${sha_lines[@]}"; do
  read -r key sha <<< "$sha_line"
  atoms[$key]+=" $sha"
done
unset tag sha

for atom_line in "${atoms[@]}"; do
  read -r tag sha <<< "$atom_line"
  basename_=${org_name}-${tag}-${sha}.img

  library_img="${NXF_SINGULARITY_LIBRARYDIR}"/$basename_
  cache_img="${NXF_SINGULARITY_CACHEDIR}"/$basename_
  [[ -e "$library_img" || -e "$cache_img" ]] && continue

  img_uri="${registry_protocol}${org_name}/${tag}:${sha}"
  singularity pull $cache_img $img_uri
done
