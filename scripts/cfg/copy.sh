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
#?   New profile.
#?
function copy () {
    local source target region

    source=$1
    target=$2
    region=$3

    printf "copying profile from: ${source} to: ${target}\n"
    xsh aws/cfg/set $(xsh aws/cfg/get "${source}" | sed "s/^${source}/${target}/") > /dev/null

    if [[ -n ${region} ]]; then
        printf "updating ${target} region to: ${region}\n"
        aws configure set region "${region}" --profile "${target}"
    fi

    xsh aws/cfg/get -m "${target}"
}

copy "$@"

exit
