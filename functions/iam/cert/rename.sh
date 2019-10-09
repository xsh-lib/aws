#? Description:
#?   Rename an IAM certificate.
#?
#? Usage:
#?   @rename <OLD_NAME> <NEW_NAME>
#?
#? Options:
#?   <OLD_NAME>  Certificate name
#?   <NEW_NAME>  Certificate name
#?
function rename () {
    if [[ $1 != $2 ]]; then
        aws iam update-server-certificate \
            --server-certificate-name "${1:?}" \
            --new-server-certificate-name "${2:?}"
    fi
}
