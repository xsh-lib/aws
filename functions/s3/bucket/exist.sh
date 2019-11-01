#? Description:
#?   Check the S3 bucket existence.
#?   The checking is across all regions.
#?
#? Usage:
#?   @exist <NAME>
#?
#? Options:
#?   <NAME>   Bucket name.
#?
#? Return:
#?   0: Exists
#?   3: Exists but not accessable
#?   4: Dosn't exist
#?   any else: Uncaught error
#?
function exist () {
    local name=${1:?}
    local out

    out=$(aws s3api head-bucket --bucket "$name" 2>&1)

    # remove any non-digit
    out=${out//[^0-9]/}

    # turn [403, 404] to [3, 4]
    return $((out % 400))
}
