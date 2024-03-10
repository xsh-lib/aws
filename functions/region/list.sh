# shellcheck disable=SC2148

#? Description:
#?   List available AWS regions. The output is sorted.
#?
#? Usage:
#?   @list
#?
#? Options:
#?   None
#?
#? Example:
#?   $ @list
#?   ap-northeast-1
#?   ap-northeast-2
#?   ...
#?
function list () {
    aws ec2 describe-regions \
        --query 'Regions[*].[RegionName]' \
        --output text \
        | sort
}
