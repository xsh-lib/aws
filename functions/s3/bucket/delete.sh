#? Description:
#?   Delete S3 bucket and all its belongings with given name.
#?
#? Usage:
#?   @delete <NAME>
#?
#? Variables:
#?   * XSH_S3_BUCKET_DELETED
#?
#?     1: Yes
#?     0: No

function delete () {
    local name=${1:?}

    if xsh aws/s3/bucket/exist "$name"; then
        aws s3 rb --force "s3://$name"
        XSH_S3_BUCKET_DELETED=1
    else
        printf "$FUNCNAME: WARNING: Bucket '%s' doesn't exist.\n" "$name" >&2
        XSH_S3_BUCKET_DELETED=0
    fi
}
