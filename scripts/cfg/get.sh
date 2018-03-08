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
    local profiles properties
    local profile property var

    xsh /ini/parser -p '__CFG_INI_' ~/.aws/config
    xsh /ini/parser -p '__CRED_INI_' ~/.aws/credentials

    profiles=( "${__CFG_INI_SECTIONS[@]#profile_}" )

    properties=(
        region:__CFG_INI_
        aws_access_key_id:__CRED_INI_
        aws_secret_access_key:__CRED_INI_
        output:__CFG_INI_
    )

    for profile in "${profiles[@]}"; do
        var=__CFG_INI_SECTIONS_${profile}
        if [[ ! ${!var+x} ]]; then  # the variable was not declared
            var=__CFG_INI_SECTIONS_profile_${profile}
        fi
        printf "%s" ${!var#profile }

        for property in "${properties[@]}"; do
            var=${property#*:}SECTIONS_${profile}_VALUES_${property%:*}
            if [[ ! ${!var+x} ]]; then  # the variable was not declared
                var=${property#*:}SECTIONS_profile_${profile}_VALUES_${property%:*}
            fi
            printf ",%s" ${!var}
        done
        printf "\n"
    done | sort
}

get "$@"

exit
