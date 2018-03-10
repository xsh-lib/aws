#!/bin/bash

#? Usage:
#?   @copy SOURCE TARGET [REGION]
#?
#? Options:
#?   SOURCE    Source profile name.
#?   TARGET    New target profile name.
#?   [REGION]  New region name.
#?
#? Output:
#?   None
#?
function copy () {
    local source target region

    source=$1
    target=$2
    region=$3

    printf "copying profile from: ${source} to: ${target}\n"
    xsh aws/cfg/set "${target}" $(xsh aws/cfg/get "${source}")

    if [[ -n ${region} ]]; then
        printf "updating ${target} region to: ${region}\n"
        aws configure set region "${region}" --profile "${target}"
    fi
}

copy "$@"

exit
