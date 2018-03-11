#!/bin/bash

#? Usage:
#?   @get [PROFILE] ...
#?
#? Options:
#?   [PROFILE]  Profile name.
#?
#? Output:
#?   List of profiles with properties in CSV format.
#?
function get () {
    local name=$1
    local profile varname base_dir

    base_dir=$(dirname "$(readlink "$0")")
    . "${base_dir}/config.conf"

    xsh /ini/parser -p "${AWS_CFG_CONFIG_ENV_PREFIX}" "${AWS_CFG_CONFIG}"
    xsh /ini/parser -p "${AWS_CFG_CREDENTIALS_ENV_PREFIX}" "${AWS_CFG_CREDENTIALS}"

    varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS[@]

    for profile in "${!varname}"; do
        if [[ -n ${name} ]]; then
            __get "${profile}" | grep "^${name},"
        else
            __get "${profile}"
        fi
    done | sort
}

function __get () {
    local profile=$1
    local property varname

    # output profile name as first field
    varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile}

    if [[ ! ${!varname+x} ]]; then  # the variable was not declared
        varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile#profile_}
    fi
    printf "%s" "${!varname#profile }"

    # output rest of properties as fields
    for property in "${AWS_CFG_PROPERTIES[@]}"; do
        varname=${property%.*}_SECTIONS_${profile}_VALUES_${property#*.}

        if [[ ! ${!varname+x} ]]; then  # the variable was not declared
            varname=${property%.*}_SECTIONS_${profile#profile_}_VALUES_${property#*.}
        fi
        printf ",%s" "${!varname}"
    done

    # end of line
    printf "\n"
}

get "$@"

exit
