# shellcheck disable=SC2148

#? Description:
#?   This script returns the long name of an AWS region based on the provided region code.
#?
#? Usage:
#?   get <REGION>
#?
#? Options:
#?   <REGION>
#?
#?   The code of the AWS region (e.g., us-west-2).
#?
#? Output:
#?   The long name of the AWS region corresponding to the provided region code.
#?
#? Example:
#?   $ @get us-west-2
#?   US West (Oregon)
#?
function get () {
    declare region=${1:?}
    aws ssm get-parameters \
        --names /aws/service/global-infrastructure/regions/"$region"/longName \
        --query 'Parameters[*].[Value]' \
        --output text
}
