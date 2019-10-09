#? Description:
#?   List AWS CloudFormation stacks.
#?   Deleted stacks won't be shown here.
#?
#? Usage:
#?   @list
#?
function list () {
    local allowed_status=(
        CREATE_COMPLETE
        CREATE_FAILED
        CREATE_IN_PROGRESS
        # DELETE_COMPLETE
        DELETE_FAILED
        DELETE_IN_PROGRESS
        IMPORT_COMPLETE
        IMPORT_IN_PROGRESS
        IMPORT_ROLLBACK_COMPLETE
        IMPORT_ROLLBACK_FAILED
        IMPORT_ROLLBACK_IN_PROGRESS
        REVIEW_IN_PROGRESS
        ROLLBACK_COMPLETE
        ROLLBACK_FAILED
        ROLLBACK_IN_PROGRESS
        UPDATE_COMPLETE
        UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
        UPDATE_IN_PROGRESS
        UPDATE_ROLLBACK_COMPLETE
        UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
        UPDATE_ROLLBACK_FAILED
        UPDATE_ROLLBACK_IN_PROGRESS
    )
    # list Stack
    aws cloudformation list-stacks --stack-status-filter "${allowed_status[@]}"
}

