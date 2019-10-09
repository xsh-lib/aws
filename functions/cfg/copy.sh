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

    if [[ -z ${source} || -z ${target} ]]; then
        printf "ERROR: parameter SOURCE and/or TARGET null or not set.\n" >&2
        return 255
    fi

    printf "copying profile from: ${source} to: ${target}\n"
    xsh aws/cfg/set $(xsh aws/cfg/get "${source}" \
                          | sed "s/^${source}/${target}/" \
                          | column -s, -t) > /dev/null

    if [[ -n ${region} ]]; then
        printf "updating ${target} region to: ${region}\n"
        aws configure set region "${region}" --profile "${target}"
    fi

    xsh aws/cfg/list
}
