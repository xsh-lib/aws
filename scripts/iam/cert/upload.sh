#!/bin/bash -e

#? Description:
#?   Upload an IAM certificate.
#?
#? Usage:
#?   @upload <NAME> <CERT_PATH> <CERT_PRIVATE_KEY_PATH>
#?
#? Options:
#?   <NAME>                   Certificate name
#?   <CERT_PATH>              Path to the certificate
#?   <CERT_PRIVATE_KEY_PATH>  Path to the certificate private key
#?
function upload () {
    aws iam upload-server-certificate \
        --server-certificate-name "${1:?}" \
        --certificate-body "$(cat "${2:?}")" \
        --private-key "$(cat "${3:?}")"
}

upload "$@"

exit
