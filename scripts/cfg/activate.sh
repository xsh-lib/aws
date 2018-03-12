#!/bin/bash

#? Usage:
#?   @activate PROFILE
#?
#? Options:
#?   PROFILE  Profile name to activate
#?
#? Output:
#?   Activated profile.
#?
function activate () {
    local profile=$1
    local base_dir property n

    base_dir=$(dirname "$(readlink "$0")")
    . "${base_dir}/config.conf"

    if [[ ${profile} == 'default' ]]; then
        printf "default profile doesn't need to activate.\n"
        return 255
    else
        :
    fi

    printf "activating profile: ${profile}\n"
    n=0  # profile properties started at $2
    for property in $(xsh aws/cfg/get "${profile}" | cut -d, -f2-); do
        aws configure set "default.${AWS_CFG_PROPERTIES[n]#*.}" "${property}"
        n=$((n+1))
    done
    xsh aws/cfg/get "${profile}"
}

activate "$@"

exit
