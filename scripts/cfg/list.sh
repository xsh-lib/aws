#!/bin/bash

#? Usage:
#?   @list
#?
#? Output:
#?   List of profiles with properties.
#?
function list () {
    local pattern

    pattern=$(xsh aws/cfg/get default \
                  | awk '{$1=""; print}')

    xsh aws/cfg/get \
        | xsh /file/mark -d, -m bold -p "${pattern}$" \
        | xsh /file/mask -d, -f4 -c1-36 -x \
        | column -s, -t
}

list "$@"

exit
