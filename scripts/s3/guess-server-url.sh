#!/bin/bash -e

#? Description:
#?   Guess S3 server URL according to current profile, output to stdin.
#?
#? Usage:
#?   @guess-server-url
#?
function guess-server-url () {
    # set default
    local delimiter='-'
    local domain_suffix=''

    # get region according to profile
    local region=$(aws configure get default.region)

    if [[ -z $region ]]; then
        return 255
    fi

    # special logic for special region CN-*
    if [[ ${region%%-*} == 'cn' ]]; then
        delimiter='.'
        domain_suffix='.cn'
    fi

    printf "https://s3%s%s.amazonaws.com%s" "${delimiter}" "${region}" "${domain_suffix}"
}

guess-server-url "$@"

exit
