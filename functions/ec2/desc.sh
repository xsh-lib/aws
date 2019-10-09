#? Description:
#?   Describe EC2 instances.
#?
#? Usage:
#?   @desc <INSTANCE_ID> [...]
#?
function desc () {
    aws ec2 describe-instances --instance-ids "$@"
}
