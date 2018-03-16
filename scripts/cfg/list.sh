#!/bin/bash

#? Usage:
#?   @list
#?
#? Output:
#?   List of profiles with properties.
#?
function list () {
    xsh aws/cfg/get -m
}

list "$@"

exit
