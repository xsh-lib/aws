#? Description:
#?   Describe CloudFormation stack resource.
#?
#? Usage:
#?   desc <STACK_NAME | STACK_ID> <RESOURCE_LOGICAL_ID>
#?
function desc () {
    aws cloudformation describe-stack-resource \
        --stack-name "${1:?}" --logical-resource-id "${2:?}"
}
