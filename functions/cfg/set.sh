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
    local name=$1
    local base_dir property n

    base_dir=${XSH_HOME}/lib/aws/functions/cfg  # TODO: use varaible instead
    . "${base_dir}/config.conf"

    if [[ -z ${name} ]]; then
        xsh log error "profile: parameter null or not set."
        return 255
    fi

    n=2  # profile properties started at $2
    for property in "${AWS_CFG_PROPERTIES[@]}"; do
        if [[ -z ${property#*.} || -z ${!n} ]]; then
            continue
        fi

        aws configure set "${property#*.}" "${!n}" --profile "${name}"
        n=$((n+1))
    done

    xsh aws/cfg/list
}
