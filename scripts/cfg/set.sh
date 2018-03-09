#!/bin/bash

#?
#?
#? Usage:
#?   @set PROFILE PROPERTIES
#?
#? Options:
#?   [PROFILE]  Profile name.
#?
#? Output:
#?
function set () {
    local name=${1:-default}
    local base_dir property n

    base_dir=$(cd "$(dirname "$0")"; pwd)
    . "${base_dir}/config.conf"

    if [[ $name != 'default' ]]; then
        name="profile.$profile"
    fi

    n=2  # profile properties started at $2
    for property in "${AWS_CFG_PROPERTIES[@]}"; do
        aws configure set ${name}.${property} ${!n}
        n=$((n+1))
    done
}

set "$@"

exit
