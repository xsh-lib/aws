#!/bin/bash

#? Usage:
#?   @list
#?
#? Output:
#?   List of profiles with properties.
#?
function list () {
    local result pattern

    result=$(xsh aws/cfg/get \
                | xsh /file/mask -d, -f4 -c1-36 -x \
                | column -s, -t)

    pattern=$(echo "${result}" \
                  | awk '$1 == "default" {OFS="[ ]+"; $1 = ".+"; $4 = ".+"; print $0}')

    echo "${result}" | xsh /file/mark -p "^${pattern}$"  # highlight activated profile
}

list "$@"

exit
