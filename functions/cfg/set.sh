#? Usage:
#?   @set PROFILE PROPERTY ...
#?
#? Options:
#?   PROFILE   Profile name.
#?   PROPERTY  Property values, in the same sequence that output by cfg/get
#?
#? Output:
#?   None.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function set () {
    declare name=$1

    if [[ -z ${name} ]]; then
        xsh log error "profile: parameter null or not set."
        return 255
    fi

    declare n=2 property  # profile properties started at $2
    for property in "${XSH_AWS_CFG_PROPERTIES[@]}"; do
        if [[ -z ${property#*.} || -z ${!n} ]]; then
            continue
        fi

        aws configure set "${property#*.}" "${!n}" --profile "${name}"
        n=$((n+1))
    done
}
