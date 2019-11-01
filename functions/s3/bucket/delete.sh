#? Description:
#?   Delete a S3 bucket and all its belongings.
#?   The deletion is across all regions.
#?
#? Usage:
#?   @delete <NAME>
#?
#? Options:
#?   <NAME>   Bucket name.
#?
#? Variables:
#?   * XSH_S3_BUCKET_DELETED
#?
#?     1: Deleted
#?     0: Not deleted
#?
function delete () {
    local name=${1:?}

    XSH_S3_BUCKET_DELETED=0

    if xsh aws/s3/bucket/exist "$name"; then
        if aws s3 rb --force "s3://$name"; then
            XSH_S3_BUCKET_DELETED=1
        fi
    else
        xsh log warning "$name: the bucket doesn't exist or is not accessable."
    fi
}
