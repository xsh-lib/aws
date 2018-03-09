#!/bin/bash

#? Usage:
#?   @get [PROFILE] ...
#?
#? Options:
#?   [PROFILE]  Profile name.
#?
#? Output:
#?
function get () {
    local profile property varname base_dir

    base_dir=$(cd "$(dirname "$0")"; pwd)
    . "${base_dir}/config.conf"

    xsh /ini/parser -p "${AWS_CFG_CONFIG_ENV_PREFIX}" "${AWS_CFG_CONFIG}"
    xsh /ini/parser -p "${AWS_CFG_CREDENTIALS_ENV_PREFIX}" "${AWS_CFG_CREDENTIALS}"

    varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS[@]
    for profile in "${!varname}"; do
        # output profile name as first field
        varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile}

        if [[ ! ${!varname+x} ]]; then  # the variable was not declared
            varname=${AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile#profile_}
        fi
        printf "%s" "${!varname#profile }"

        # output rest of properties as fields
        for property in "${AWS_CFG_PROPERTIES[@]}"; do
            varname=${property%\.*}_SECTIONS_${profile}_VALUES_${property#*\.}

            if [[ ! ${!varname+x} ]]; then  # the variable was not declared
                varname=${property%\.*}_SECTIONS_${profile#profile_}_VALUES_${property#*\.}
            fi
            printf ",%s" "${!varname}"
        done

        # end of line
        printf "\n"
    done | sort | column -s, -t
}

get "$@"

exit
