#? Description:
#?   Print out the environment variables used by aws/cfn/deploy.
#?
#? Usage:
#?   @echo
#?
function echo () {
    declare name

    for name in "${XSH_AWS_CFN__CFG_PROPERTY_NAMES[@]}"; do
        if xsh /array/is-array "${name}"; then
            name="${name}[*]"
        fi
        printf "%s='%s'\n" "${name}" "${!name}"
    done
}
