#? Description:
#?   Check if support command is available in AWS CLI.
#?   AWS Premium Support Subscription is required to use support in AWS CLI.
#?
#? Usage:
#?   @is-callable
#?
#? Return:
#?   0: Available
#?   != 0: Not avaiable
#?
#? Output:
#?   None
#?
function is-callable () {
    # aws support command is availble only in region us-east-1 by now.
    # https://docs.aws.amazon.com/general/latest/gr/rande.html#awssupport_region
    aws --region us-east-1 support describe-services >/dev/null 2>&1
}
