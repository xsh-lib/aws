#? Usage:
#?   @delete PROFILE [...]
#?
#? Options:
#?   PROFILE  Profile name to delete
#?
#? Output:
#?   None
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function delete () {
    if [[ $# -eq 0 ]]; then
        xsh log error "profile: parameter null or not set."
        return 255
    fi

    declare profile
    for profile in "$@"; do
        if [[ ${profile} == 'default' ]]; then
            xsh log error "the default profile can't be deleted."
            return 255
        fi

        printf "deleting profile: ${profile}\n"
        xsh /util/sed-regex-inplace "/^\[profile ${profile}\]$/,/^\[.+\]$/{/^\[profile ${profile}\]$/d; /^[^[]+$/d;}" "${XSH_AWS_CFG_CONFIG}"
        xsh /util/sed-regex-inplace "/^\[${profile}\]$/,/^\[.+\]$/{/^\[${profile}\]$/d; /^[^[]+$/d;}" "${XSH_AWS_CFG_CREDENTIALS}"
    done
}
