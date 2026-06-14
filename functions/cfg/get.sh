#? Usage:
#?   @get [PROFILE] ...
#?
#? Options:
#?   [PROFILE]  Profile name.
#?
#? Output:
#?   List of profiles with properties.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function get () {

    function __get () {
        declare profile=$1 \
                property varname value

        # output profile name as first field
        varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile}

        # `${!varname...}` is bash-only indirection; `eval` does it portably
        # (the variable name is built from controlled prefixes + parsed
        # section names, not arbitrary input).
        if ! eval "[[ \${${varname}+x} ]]"; then  # the variable was not declared
            varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile#profile_}
        fi
        eval "value=\${${varname}#profile }"
        printf "%s" "${value}"

        # output rest of properties as fields
        for property in "${XSH_AWS_CFG_PROPERTIES[@]:?}"; do
            varname=${property%.*}_SECTIONS_${profile}_VALUES_${property#*.}

            if ! eval "[[ \${${varname}+x} ]]"; then  # the variable was not declared
                varname=${property%.*}_SECTIONS_${profile#profile_}_VALUES_${property#*.}
            fi
            eval "value=\${${varname}}"
            printf ",%s" "${value}"
        done

        # end of line
        printf "\n"
    }

    declare name=$1

    xsh /ini/parser -a -p "${XSH_AWS_CFG_CONFIG_ENV_PREFIX}" "${XSH_AWS_CFG_CONFIG:?}"
    xsh /ini/parser -a -p "${XSH_AWS_CFG_CREDENTIALS_ENV_PREFIX}" "${XSH_AWS_CFG_CREDENTIALS:?}"

    # shellcheck disable=SC2125
    declare varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS[@] \
            profile
    declare -a profiles
    # `${!varname}` array indirection (varname holds `NAME[@]`) is bash-only;
    # `eval` expands the named array portably
    eval "profiles=( \"\${${varname}}\" )"

    for profile in "${profiles[@]}"; do
        if [[ -n ${name} ]]; then
            __get "${profile}" | grep "^${name}," || :
        else
            __get "${profile}"
        fi
    done | sort
}
