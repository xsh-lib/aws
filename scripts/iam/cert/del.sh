#!/bin/bash -e

#? Description:
#?   Delete an IAM certificate.
#?
#? Usage:
#?   @del <NAME>
#?
#? Options:
#?   <NAME>  Certificate name
#?
function del () {
    aws iam delete-server-certificate \
        --server-certificate-name "${1:?}"
}

del "$@"

exit
