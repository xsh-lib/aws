#? Description:
#?   Delete CloudFormation stack.
#?
#? Usage:
#?   @delete <STACK_ID | STACK_NAME>
#?
#? Options:
#?   <STACK_ID | STACK_NAME>
#?
#?   The name or unique stack ID of the stack that is deleting.
#?
function delete () {
    # delete stack
    aws cloudformation delete-stack --stack-name "${1:?}" && \
        # block to wait stack delete complete
        aws cloudformation wait stack-delete-complete --stack-name "${1:?}"
}
