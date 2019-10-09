#? Description:
#?   Describe CloudFormation stack.
#?
#? Usage:
#?   @desc <STACK_NAME | STACK_ID>
#?
function desc () {
    aws cloudformation describe-stacks --stack-name "${1:?}"
}
