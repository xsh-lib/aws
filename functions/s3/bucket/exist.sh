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
    declare name=${1:?}
    declare out

    # example output for the unexist bucket and the exist bucket but not accessable:
    #   - An error occurred (404) when calling the HeadBucket operation: Not Found
    #   - An error occurred (403) when calling the HeadBucket operation: Forbidde
    # suppress the stdout, and output the stderr to stdout.
    out=$(aws s3api head-bucket --bucket "$name" 2>&1 1>/dev/null || :)

    # remove any non-digit
    out=${out//[^0-9]/}

    # turn [403, 404] to [3, 4]
    return $((out % 400))
}
