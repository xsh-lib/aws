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

    if [[ ${profile} == 'default' ]]; then
        printf "default profile doesn't need to activate.\n"
        return 255
    else
        :
    fi

    printf "activating profile: ${profile}\n"
    xsh aws/cfg/copy "${profile}" default > /dev/null
    xsh aws/cfg/get "${profile}"
}

activate "$@"

exit
