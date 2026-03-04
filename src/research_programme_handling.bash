#/usr/bin/env bash
#
# Provides the tools required to set or derive RESEARCH_PROGRAMME on the CHPC.
#
# These tools assume that all but one of the GIDs associated with the USER
#  correspond to research programmes under which they may request CHPC
#  resources. 

set_research_programme () {
	local -a programmes
	read -ra programmes < <(id -Gn | cut -d ' ' -f 2-)

	local num_programmes=${#programmes[@]}
	if (( num_programmes == 0 )); then
		echo >&2 'ERROR: Failed to resolve valid programmes.'
		return 1
	fi

	# NOTE: quiet_fail only suppresses failures to resolve PROGRAMME.
	local OPTIND OPTARG OPTERR opt usage interactive=true quiet_fail=false
	usage="Usage: set_research_programme [-h] [-l] [-p [-q]] [PROGRAMME]"
	while getopts 'hlpq' opt; do
		case $opt in
			h) echo "$usage"; return 0;;		# "help"
			l) echo "${programmes[@]}"; return 0;;	# "list"
			p) interactive=false;;			# "passive"
			q) quiet_fail=true;;			# "quiet"
			*) echo >&2 "$usage"; return 2;;
		esac
	done
	if $interactive && $quiet_fail; then
		echo >&2 'WARNING: "-q" passed without "-p"; ignoring.'
		quiet_fail=false
	fi
	shift $((OPTIND - 1))
	if (( $# > 1 )); then
		echo -e >&2 "ERROR: More than one PROGRAMME specified.\n$usage"
		return 3
	fi
	local programme was_specified=false is_valid=true
	[[ -n $1 ]] && { programme=$1; was_specified=true; is_valid=false; }

	if [[ ! -v programme ]] && (( num_programmes == 1 )); then
		programme=${programmes[0]}
	fi

	if [[ ! -v programme ]] && $interactive; then
		local REPLY endash=$'\u2013'
		local abort_reply=$(( num_programmes + 1 ))
		local paren_str="1$endash$num_programmes; $abort_reply aborts"
		local full_range="1$endash$abort_reply"
		local PS3="Select desired research programme ($paren_str): "
		select programme in "${programmes[@]}" 'abort'; do
			(( REPLY == abort_reply )) && return 4
			[[ -n $programme ]] && break
			echo >&2 "Invalid; select a number in ${full_range}."
		done
	fi

	if [[ ! -v programme ]]; then
		! $quiet_fail && echo >&2 'ERROR: Failed to resolve PROGRAMME.'
		return 5
	fi

	if ! $was_specified; then
		export RESEARCH_PROGRAMME=$programme
		return 0
	fi

	local known_programme
	for known_programme in "${programmes[@]}"; do
		if [[ $programme == "$known_programme" ]]; then
			is_valid=true
			break
		fi
	done

	if $is_valid; then
		export RESEARCH_PROGRAMME=$programme
		return 0
	fi

	echo >&2 "ERROR: Invalid PROGRAMME: $programme; must be one of:"
	echo >&2 "${programmes[@]}"
	return 6
}
