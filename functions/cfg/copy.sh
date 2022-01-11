#? Usage:
#?   @copy SOURCE TARGET [REGION]
#?
#? Options:
#?   SOURCE    Source profile name.
#?   TARGET    New target profile name.
#?   [REGION]  New region name.
#?
#? Output:
#?   None.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function copy () {
    declare source=$1 target=$2 region=$3

    if [[ -z ${source} || -z ${target} ]]; then
        xsh log error "source/target: parameter null or not set."
        return 255
    fi

    if [[ ${source} == ${target} ]]; then
        xsh log error "the source and the target are the same."
        return 255
    fi

    printf "copying profile from: %s to: %s\n" "${source}" "${target}"
    xsh aws/cfg/set $(xsh aws/cfg/get "${source}" \
                          | sed "s/^${source}/${target}/")

    if [[ -n ${region} ]]; then
        printf "updating %s region to: %s\n" "${target}" "${region}"
        aws configure set region "${region}" --profile "${target}"
    fi
}
