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

command -v singularity >/dev/null || module load chpc/singularity

# TODO: Some of these should probably sourced from a central config(?)
registry_protocol='docker://'
org_name='ontresearch'
wf_assets=$HOME/.nextflow/assets/epi2me-labs/wf-human-variation
base_conf=$wf_assets/base.config
# num_imgs=10
readonly registry_protocol org_name wf_assets base_conf

nxf_format_basename () {
  local tag=$1
  local sha=$2
  printf %s-%s-%s.img $org_name $tag $sha
}

docker_uri () {
  local tag=$1
  local sha=$2
  printf docker://%s/%s:%s $org_name $tag $sha
}

readarray -t tag_lines < <(grep '"ont' $base_conf)
tag_lines=("${tag_lines[@]#*/}")
tag_lines=("${tag_lines[@]%\}\"}")
tag_lines=("${tag_lines[@]/:*wf./ }")

readarray -t sha_lines < <(grep '"sha' $base_conf)
sha_lines=("${sha_lines[@]//[\"\|=]}")

declare -A atoms
for tag_line in "${tag_lines[@]}"; do
  IFS=' ' read -r tag key rest <<< "$tag_line"
  [[ -z $rest ]] || {
    echo 'Too many words in $tag_line (expected two):' "$tag_line"
    exit 1
  }
  atoms[$key]=$tag
done
unset key rest
for sha_line in "${sha_lines[@]}"; do
  IFS=' ' read -r key sha rest <<< "$sha_line"
  [[ -z $rest ]] || {
    echo 'Too many words in $sha_line (expected two):' "$sha_line"
    exit 2
  }
  atoms[$key]+=" $sha"
done
unset tag sha

for atom_line in "${atoms[@]}"; do
  IFS=' ' read -r tag sha <<< "$atom_line"
  basename_=$(nxf_format_basename $tag $sha)

  [[ -e "${NXF_SINGULARITY_LIBRARYDIR}"/$basename_ ]] && continue

  path_="${NXF_SINGULARITY_CACHEDIR}"/$basename_
  [[ -e "$path_" ]] && singularity inspect "$path_" 1>/dev/null 2>&1 && continue

  uri=$(docker_uri $tag $sha)
  singularity pull $path_ $uri
done
