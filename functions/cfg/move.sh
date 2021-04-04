#? Usage:
#?   @move SOURCE TARGET
#?
#? Options:
#?   SOURCE    Source profile name.
#?   TARGET    Target profile name.
#?
#? Output:
#?   None.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function move () {
    declare source=$1 target=$2

    xsh aws/cfg/copy "${source}" "${target}"
    xsh aws/cfg/delete "${source}"
}
