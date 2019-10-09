#? Description:
#?   Delete an IAM certificate.
#?
#? Usage:
#?   @delete <NAME>
#?
#? Options:
#?   <NAME>  Certificate name
#?
function delete () {
    aws iam delete-server-certificate \
        --server-certificate-name "${1:?}"
}
