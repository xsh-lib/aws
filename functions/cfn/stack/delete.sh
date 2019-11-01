#? Description:
#?   Delete CloudFormation stack.
#?
#? Usage:
#?   @delete [-r REGION] <-s STACK_ID | STACK_NAME>
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   <-s STACK_ID | STACK_NAME>
#?
#?   The name or unique stack ID of the stack that is deleting.
#?
function delete () {
    local OPTIND OPTARG opt

    local -a region_opt
    local stack_name

    while getopts r:s: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            s)
                stack_name=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $stack_name ]]; then
        xsh log error "parameter STACK_NAME null or not set."
        return 255
    fi

    # delete stack
    aws "${region_opt[@]}" cloudformation delete-stack --stack-name "$stack_name" && \
        # block to wait stack delete complete
        aws "${region_opt[@]}" cloudformation wait stack-delete-complete --stack-name "$stack_name"
}
