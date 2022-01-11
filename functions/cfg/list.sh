#? Usage:
#?   @list
#?
#? Output:
#?   List of profiles with properties.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function list () {
    declare -a properties=(
        "profile"
        "${XSH_AWS_CFG_PROPERTIES[@]:?}"
    )

    declare i=1 property sensitive
    for property in "${properties[@]}"; do
        if [[ ${property#*.} == 'aws_secret_access_key' ]]; then
            sensitive=$i
            break
        fi
        i=$((i+1))
    done

    declare result sep str
    result=$(
        {
            # header
            sep=""
            for property in "${properties[@]}"; do
                str=${property#*.}
                printf "%s" "${sep}${str}"
                sep=","
            done
            printf "\n"

            sep=""
            for property in "${properties[@]}"; do
                str=${property#*.}
                printf "%s%s" "${sep}" "$(xsh /string/repeat/1 '-' ${#str})"
                sep=","
            done
            printf "\n"

            # list config
            xsh aws/cfg/get \
                | xsh /file/mask -d, -f${sensitive} -c1-36 -x  # mask credentials
        } | sed 's|,|, \| |g' \
          | column -s, -t)  # output as table format

    # highlight pattern
    declare pattern
    pattern=$(
        echo "${result}" \
            | awk -F\| '{
                  val = ""
                  for (i=2; i<=NF; i++) {
                      val = val $i
                  }
                  gsub(" ", "", $1)
                  a[$1] = val
              } END {
                  p = ""
                  for (key in a) {
                      if (a[key] == a["default"])
                          p = (p ? p "|" : p) "^" key " "
                  }
                  print p
              }')

    echo "${result}" | xsh /file/mark -p "${pattern}"  # highlight activated profile
}
