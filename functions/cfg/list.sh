#? Usage:
#?   @list
#?
#? Output:
#?   List of profiles with properties.
#?
function list () {
    local result pattern
    local i sep str properties property sensitive base_dir

    base_dir="${XSH_HOME}/lib/aws/functions/cfg"  # TODO: use varaible instead
    . "${base_dir}/config.conf"

    properties=(
        "profile"
        "${AWS_CFG_PROPERTIES[@]}"
    )

    i=1
    for property in "${properties[@]}"; do
        if [[ ${property#*.} == 'aws_secret_access_key' ]]; then
            sensitive=$i
        fi
        i=$((i+1))
    done

    result=$(
        {
            sep=""
            for property in "${properties[@]}"; do
                str=${property#*.}
                printf "${sep}${str}"
                sep=","
            done
            printf "\n"

            sep=""
            for property in "${properties[@]}"; do
                str=${property#*.}
                printf "%s" "${sep}$(xsh /string/repeat/1 '-' ${#str})"
                sep=","
            done
            printf "\n"

            xsh aws/cfg/get \
                | xsh /file/mask -d, -f4 -c1-36 -x
        } | column -s, -t)

    pattern=$(
        echo "${result}" \
            | awk -v secret_field=${sensitive} \
                  '$1 == "default" {
                      OFS="[ ]+"
                      $1 = ".+"
                      if (secret_field) {
                         $secret_field = ".+"
                      }
                      print $0
                  }')

    echo "${result}" | xsh /file/mark -p "^${pattern}$"  # highlight activated profile
}
