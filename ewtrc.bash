# Prepares the user's environment to run EPI2ME workflows on the CHPC.

# --- Documentation ---
: <<'__ewtrc_DOC_'
Usage:
  With ewtrc.bash located in directory EWT_HOME, do

    source EWT_HOME/ewtrc.bash

  Example: source /home/rfranklin/epi2me-wf-tools/ewtrc.bash

  To have ewtrc.bash run at login, add the above line toward the end of your
  $HOME/.bashrc file. While ewtrc.bash can derive EWT_HOME itself, the safer,
  more readable option is to set it before soucing ewtrc.bash; e.g.,

    EWT_HOME=/home/rfranklin/epi2me-wf-tools
    source "$EWT_HOME/ewtrc.bash"

Description:
  The main focus of this script is to ensure that the nextflow and singularity
  tools have everything they need to run EPI2ME Labs workflows on the CHPC.

Exports (variables):
  In the below lists, variables tagged with an 'r' (in brackets) are respectful;
  i.e., if they are set before ewtrc.bash is source, it respects the set value.
  (Note that, while the set values are respected, they are still checked to
    ensure that they are on an appropriate filesystem; e.g., NXF_WORK must be
    on USER_LUSTRE.)

  General:
    - (r) EWT_HOME: Path to the epi2me-wf-tools directory. (Derived if not set.)
    - USER_LUSTRE: Path to user's personal lustre directory.
    - PATH: Appends the EWT_HOME/tools directory to the user's PATH variable.

  Nextflow:
    - (r) NXF_HOME: Nextflow's home directory. (Default: $HOME/.nextflow)
    - (r) NXF_SINGULARITY_CACHEDIR: Directory where Nextflow will store cached
        Singularity images. (Default: $USER_LUSTRE/singularity_cache; not to be
        confused with Singularity's cache directory, or with Nextflow's local
        Singularity library directory!)
    - (r) NXF_WORK: Directory where intermediate workflow artifacts live.
        (Default: $USER_LUSTRE/nextflow_work)
    - NXF_DISABLE_CHECK_LATEST: Disables automatic workflow updates.
        (Only set on nodes that have access to the internet.)
    - NXF_OFFLINE: Tells Nextflow to run in offline mode.
        (Only set on nodes that don't have access to the internet.)
    - NXF_ANSI_LOG: Controls the use of ANSI escape sequences in Nextflow logs.
        (Only set during non-interactive sessions to disable ANSI sequences.)

  Singularity:
    - SINGULARITY_DISABLE_CACHE: Turns off the caching that happens when
        Singularity builds an image (usually as part of a "pull" call).
        (Only set on nodes that have access to the internet.)

  Non-public:
    Along with the above variables, ewtrc.bash exports a number of "non-public"
    variables; i.e., variables provided for internal use by other tools in this
    toolkit, or by developers of other toolkits.
    (See the __ewtrc_DOC_dev_ doc block for more detail.)

Exports (functions):
  Utility:
    - tless(): Useful for viewing TSV files that contain data in columns.
        EPI2ME Labs workflows often produce such files as part of their output;
        they often don't render nicely when viewed via "less -S" (or similar).
        (Only exported for interactive sessions; See "tless -h" for usage.)
__ewtrc_DOC_

# --- Preflight checks ---
# Checks whether it's safe for initialisation scripts to print to stdout/stderr.
# NOTE:   The PBS User Guide suggests adding [[ -v PBS_ENVIRONMENT ]] to this,
#           but that suppresses error reporting for interactive jobs as well.
_ewtrc_verbose() { [[ $- == *i* ]]; }

# An echo replacement that's safe to use in initialisation scripts; i.e., that's
#   safe to use in scripts sourced in .bashrc or similar.
_ewtrc_echo() { _ewtrc_verbose && echo -e "$@"; }

# Resolves the (absolute) dirname for a given path.
# NOTE:   _ewtrc_derive_dirname cannot be broken out into src/utils because
#           sourcing from there requires EWT_HOME be resolved first.
_ewtrc_derive_dirname() {
  local full_path
  full_path="$(realpath "$1" 2>/dev/null)" || {
    _ewtrc_echo >&2 "ERROR: Unable to resolve realpath for $1."
    return 3
  }
  echo "${full_path%/*}"
}

[[ ${BASH_SOURCE[0]} != "$0" ]] || {
  _ewtrc_echo >&2 "ERROR: ${BASH_SOURCE[0]} can only be sourced."
  exit 1
}

# Derive EWT_HOME if it wasn't provided.
[[ -v EWT_HOME ]] || {
  EWT_HOME=$(_ewtrc_derive_dirname "${BASH_SOURCE[0]}") || unset EWT_HOME
}

[[ -v EWT_HOME ]] || {
  _ewtrc_echo >&2 'ERROR: Unable to resolve EWT_HOME.'
  return 3
}

# --- Function definitions ---
# Checks whether the node (nominally) has access to the internet.
_ewtrc_online_node() { [[ :$_EWTRC_ONLINE_NODES: == *":$(hostname):"* ]]; }

# Checks that the calling environment resembles one where ewtrc.bash succeeded.
_ewtrc_loaded_ok() {
  [[ -v _EWTRC_ONLINE_NODES ]] || return
  declare -F _ewtrc_online_node &>/dev/null || return
  local -a funcs vars
  funcs=(_ewtrc_{verbose,echo,derive_dirname})
  vars=(
    {EWT,NXF}_HOME _EWTRC_LUSTRE_{GROUPS,USERS}_ROOT USER_LUSTRE
    NXF_{WORK,SINGULARITY_CACHEDIR,ANSI_LOG}
  )
  if _ewtrc_online_node; then
    vars+=(NXF_DISABLE_CHECK_LATEST SINGULARITY_DISABLE_CACHE)
  else
    vars+=(NXF_OFFLINE)
  fi
  [[ $- == *i* ]] && vars+=(NXF_ANSI_LOG)

  declare -F "${funcs[@]}" &>/dev/null &&
    declare -p "${vars[@]}" &>/dev/null &&
    [[ :$PATH: == *":$EWT_HOME/tools:"* ]]
  # TODO: Add check for the nextflow and singularity modules
  # TODO: Implement a sensible check that -P is in effect for cd on non-cnodes.
  # option:
  #   IFS='=' read -rt 1 junk val < <(alias cd) &&
  #     [[ $val == "'cd -P'" ]] || return
}

# Ensures that ewtrc.bash does not polute the user's environment.
ewtrc_cleanup() {
  unset -v ewtrc_qopt
  unset -f constrain_paths ewtrc_cleanup
}

# --- Environment setup ---
## --- In-package sources ---
# We do this up front because source calls don't play nice with traps on RETURN.
source "$EWT_HOME/src/utils/constrain_paths.bash"

## --- Site-specific constants ---
_EWTRC_ONLINE_NODES='login1:dtn'
_EWTRC_LUSTRE_GROUPS_ROOT=/mnt/lustre/groups
_EWTRC_LUSTRE_USERS_ROOT=/mnt/lustre/users

## --- Derived vars ---
export USER_LUSTRE=$_EWTRC_LUSTRE_USERS_ROOT/$USER

### --- Respectful vars ---
# (i.e., vars that can be set by the user before sourcing ewtrc.bash)
# NB:     This fallback for NXF_WORK should not be treated as a default!
#           None of the tools that this package provides are designed to use
#           a monolithic NXF_WORK directory like this.
: "${NXF_HOME:=$HOME/.nextflow}"
: "${NXF_WORK:=$USER_LUSTRE/nextflow_work}"
: "${NXF_SINGULARITY_CACHEDIR:=$USER_LUSTRE/singularity_cache}"

## --- Provided non-public vars/funcs ---
export -f _ewtrc_{verbose,echo,derive_dirname,online_node,loaded_ok}
export _EWTRC_{ONLINE_NODES,LUSTRE_{GROUPS,USERS}_ROOT}

# NOTE:   The trap reset must happen in the global scope.
trap 'ewtrc_cleanup; trap - RETURN' RETURN

# NB: === NO SOURCE CALLS WHILE ABOVE TRAP IS IN EFFECT! ===

## --- Module loads ---
# This is actually just a call to `module use` that prepends the appropriate
#   directory (which houses the nextflow module, among others) to MODULEPATH.
module load chpc/BIOMODULES || {
  _ewtrc_echo >&2 'ERROR: Could not add BIOMODULES to MODULEPATH.'
  return 4
}
module load nextflow chpc/singularity 2>/dev/null || {
  _ewtrc_echo >&2 'ERROR: nextflow and/or singularity module load failed.'
  return 5
}

## --- Pathy variables handling ---
# NOTE:   Pathy vars checked here should not be exported before this check.
_ewtrc_verbose && unset ewtrc_qopt || ewtrc_qopt='-q'
constrain_paths "$ewtrc_qopt" 'NXF_WORK NXF_SINGULARITY_CACHEDIR' USER_LUSTRE &&
  constrain_paths "$ewtrc_qopt" EWT_HOME "${!_EWTRC_LUSTRE_@}" HOME &&
  constrain_paths "$ewtrc_qopt" NXF_HOME USER_LUSTRE HOME ||
  return 6
export NXF_{WORK,SINGULARITY_CACHEDIR} {EWT,NXF}_HOME

ewtrc_cleanup
trap - RETURN

# === SOURCE CALL EMBARGO LIFTED ===

## --- Internet access-related setup ---
# "If we're running on a node with access to the internet."
if _ewtrc_online_node; then
  export NXF_DISABLE_CHECK_LATEST='true'
  export SINGULARITY_DISABLE_CACHE='true'
else
  export NXF_OFFLINE='true'
fi

# This check ensures that subsequent `source ewtrc.bash` calls don't add copies.
[[ :$PATH: == *":$EWT_HOME/tools:"* ]] || export PATH=$EWT_HOME/tools:$PATH

## --- Aliases (all nodes/sessions) ---
# Prevents HOME from leaking into nextflow's singularity auto mounts via PWD.
alias cd='cd -P'

## --- (Non-)interactive session-only setup ---
if [[ $- == *i* ]]; then
  source "$EWT_HOME/src/utils/tless.bash"
  export -f tless
  # Run `less` with ANSI colors support (used in nextflow log files) by default.
  alias less="less -R"
else
  # Nextflow handles the interactive case.
  export NXF_ANSI_LOG='false'
fi

# --- Documentation (devs/maintainers) ---
: <<'__ewtrc_DOC_dev_'
For developers/maintainers:
  In addition to what is documented in __ewtrc_DOC_, ewtrc.bash provides a
  number of "non-public" variables and functions. These should never be
  relevant to the user beyond the fact that they exist in their environment.

Exports (variables):
  Non-public: (i.e., for use in this script, or by other things in EWT_HOME.)
    - _EWTRC_ONLINE_NODES: A colon-seperated list of the hostnames of nodes that
        have access to the internet.
    - _EWTRC_LUSTRE_GROUPS_ROOT: The path to the lustre directory that houses
        all the various groups' lustre directories.
        (Allows more freedom for some of the paths specified above.)
    - _EWTRC_LUSTRE_USERS_ROOT: The path to the lustre directory that houses
        all the users' lustre directories.
        (Allows more freedom for some of the paths specified above.)

Exports (functions):
  Non-public:
    - _ewtrc_verbose: Encodes whether it's safe to print to stdout/stderr.
        (Allows verbose error reporting without breaking tools like scp.)
    - _ewtrc_echo: _ewtrc_verbose-aware replacement for echo; use it in any
        code that might run during scp operations (or similar).
    - _ewtrc_derive_dirname: (Crudely) resolves the directory that hosts the
        source file it's called in. This should ONLY be used to detect where
        run scripts like this one reside, so the user isn't burdened with
        manually setting variables like EWT_HOME. (It's better if they do, but
        it's best if we don't expect it of them.)
    - _ewtrc_online_node: Checks whether the host node (nominally) has access
        to the internet; i.e., whether it is one of the nodes listed in
        _EWTRC_ONLINE_NODES.
        (NOTE: This implementation assumes that _EWTRC_ONLINE_NODES -- currently
          implemented as a site-specific constant -- is constructed such as to
          be compatible with the output of a "hostname" call.)
    - _ewtrc_loaded_ok: Checks that the calling environment resembles one where
        ewtrc.bash was sourced without error. It acts as a safeguard; when
        called at the start of a script, it allows said script's author to
        confidently presume that the various bits provided by this script exist
        in it's environment; i.e., said author doesn't need to check for
        existence around every corner.
        Example usage:
          declare -F _ewtrc_loaded_ok &>/dev/null && $_ || exit 42
        (We use exit code 42 to free up the lower codes for script authors' use,
        and so such a failure is easily recognisable.)
__ewtrc_DOC_dev_
