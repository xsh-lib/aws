#? Description:
#?   Create S3 bucket with given name.
#?
#? Usage:
#?   @create <NAME>
#?
#? Variables:
#?   * XSH_S3_BUCKET_CREATED
#?
#?     1: Yes
#?     0: No

function create () {
    local name=${1:?}

    if xsh aws/s3/bucket/exist "$name"; then
        printf "$FUNCNAME: WARNING: Bucket '%s' already exists.\n" "$name" >&2
        XSH_S3_BUCKET_CREATED=0
    else
        aws s3 mb "s3://$name"
        XSH_S3_BUCKET_CREATED=1
    fi
}
