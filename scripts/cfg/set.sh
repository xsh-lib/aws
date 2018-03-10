#!/bin/bash

#? Usage:
#?   @set PROFILE PROPERTY ...
#?
#? Options:
#?   PROFILE   Profile name.
#?   PROPERTY  Property values, in the same sequence that output by cfg/get
#?
#? Output:
#?   None
#?
function set () {
    local name=${1:-default}
    local base_dir property n

    base_dir=$(cd "$(dirname "$0")"; pwd)
    . "${base_dir}/config.conf"

    n=2  # profile properties started at $2
    for property in "${AWS_CFG_PROPERTIES[@]}"; do
        aws configure set "${property#*.}" "${!n}" --profile "${name}"
        n=$((n+1))
    done
}

set "$@"

exit
