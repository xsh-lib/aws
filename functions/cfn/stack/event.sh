#? Description:
#?   Show CloudFormation stack events.
#?
#? Usage:
#?   @event [-r REGION] [-e] <-s STACK_ID | STACK_NAME>
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-e]
#?
#?   Show error events only.
#?
#?   <-s STACK_ID | STACK_NAME>
#?
#?   The name or unique stack ID of the stack.
#?
function event () {
    local OPTIND OPTARG opt

    local -a region_opt
    local error stack_name

    while getopts r:es: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            e)
                error=1
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

    local -r error_match_options=( -B1 -A7 '(CREATE_FAILED|UPDATE_FAILED)' )

    if [[ $error -eq 1 ]]; then
        aws "${region_opt[@]}" cloudformation describe-stack-events --stack-name "$stack_name" \
            | egrep "${error_match_options[@]}" || :
    else
        aws "${region_opt[@]}" cloudformation describe-stack-events --stack-name "$stack_name"
    fi
}
