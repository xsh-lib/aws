#? Usage:
#?   @activate PROFILE
#?
#? Options:
#?   PROFILE  Profile name to activate
#?
#? Output:
#?   None.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function activate () {
    declare profile=$1

    if [[ -z ${profile} ]]; then
        xsh log error "profile: parameter null or not set."
        return 255
    elif [[ ${profile} == 'default' ]]; then
        xsh log error "default profile doesn't need to activate."
        return 255
    else
        :
    fi

    printf "activating profile: %s\n" "${profile}"
    xsh aws/cfg/set $(xsh aws/cfg/get "${profile}" \
                          | sed "s/^${profile}/default/")
}
