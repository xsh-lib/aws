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
                property varname

        # output profile name as first field
        varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile}

        if [[ ! ${!varname+x} ]]; then  # the variable was not declared
            varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS_${profile#profile_}
        fi
        printf "%s" "${!varname#profile }"

        # output rest of properties as fields
        for property in "${XSH_AWS_CFG_PROPERTIES[@]:?}"; do
            varname=${property%.*}_SECTIONS_${profile}_VALUES_${property#*.}

            if [[ ! ${!varname+x} ]]; then  # the variable was not declared
                varname=${property%.*}_SECTIONS_${profile#profile_}_VALUES_${property#*.}
            fi
            printf ",%s" "${!varname}"
        done

        # end of line
        printf "\n"
    }

    declare name=$1

    xsh /ini/parser -a -p "${XSH_AWS_CFG_CONFIG_ENV_PREFIX}" "${XSH_AWS_CFG_CONFIG:?}"
    xsh /ini/parser -a -p "${XSH_AWS_CFG_CREDENTIALS_ENV_PREFIX}" "${XSH_AWS_CFG_CREDENTIALS:?}"

    declare varname=${XSH_AWS_CFG_CONFIG_ENV_PREFIX}SECTIONS[@] \
            profile

    for profile in "${!varname}"; do
        if [[ -n ${name} ]]; then
            __get "${profile}" | grep "^${name}," || :
        else
            __get "${profile}"
        fi
    done | sort
}
