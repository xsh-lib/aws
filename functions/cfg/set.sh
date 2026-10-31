#? Usage:
#?   @set PROPERTIES
#?
#? Options:
#?   PROPERTIES  Property values, delimited by comma, in the same format that output by cfg/get
#?
#? Output:
#?   None.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function set () {
    declare OLDIFS=${IFS}
    IFS=,
    set -- $*
    IFS=${OLDIFS}

    declare name=$1

    if [[ -z ${name} ]]; then
        xsh log error "profile: parameter null or not set."
        return 255
    fi

    declare n=2 property value  # profile properties started at $2
    for property in "${XSH_AWS_CFG_PROPERTIES[@]:?}"; do
        property=${property#*.}
        # `${!n}` (positional indirection) is bash-only; `${*:N:1}` is portable
        value=${*:$((n)):1}
        if [[ ${name} == default ]]; then
            aws configure set "${name}.${property:?}" "${value}"
        else
            aws configure set "${property:?}" "${value}" --profile "${name}"
        fi
        n=$((n+1))
    done
}
