#? Description:
#?   Check EC2 key pair existence.
#?
#? Usage:
#?   @exist <NAME>
#?
function exist () {
    aws ec2 describe-key-pairs --key-names "${1:?}" >/dev/null 2>&1
}
