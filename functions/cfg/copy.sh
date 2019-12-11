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
#? @xsh /trap/err -eE
#? @subshell
#?
function copy () {
    declare source target region

    source=$1
    target=$2
    region=$3

    if [[ -z ${source} || -z ${target} ]]; then
        xsh log error "source/target: parameter null or not set."
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
