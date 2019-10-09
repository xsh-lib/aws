#? Description:
#?   Check the S3 bucket existence.
#?
#? Usage:
#?   @exist <BUCKET>
#?
#? Return:
#?   0: Exists
#?   != 0: Dosn't exist
#?
function exist () {
    aws s3 ls s3://${1:?} >/dev/null 2>&1
}
