#!/bin/bash -e

#? Description:
#?   List IAM certificates.
#?
#? Usage:
#?   @list
#?
#? Options:
#?   None
#?
#? Output:
#?   IAM certificate list.
#?
function list () {
    aws iam list-server-certificates
}

list "$@"

exit
