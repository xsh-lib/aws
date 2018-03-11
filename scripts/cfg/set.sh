#!/bin/bash

#? Usage:
#?   @set PROFILE PROPERTY ...
#?
#? Options:
#?   PROFILE   Profile name.
#?   PROPERTY  Property values, in the same sequence that output by cfg/get
#?
#? Output:
#?   Updated profile.
#?
function set () {
    local name=${1:-default}
    local base_dir property n

    base_dir=$(dirname "$(readlink "$0")")
    . "${base_dir}/config.conf"

    n=2  # profile properties started at $2
    for property in "${AWS_CFG_PROPERTIES[@]}"; do
        aws configure set "${property#*.}" "${!n}" --profile "${name}"
        n=$((n+1))
    done

    xsh aws/cfg/get "${name}"
}

set "$@"

exit
