#? Description:
#?   Show CloudFormation stack events.
#?
#? Usage:
#?   @event [-e] <STACK_ID | STACK_NAME>
#?
#? Options:
#?   [-e]                      Show error events only.
#?   <STACK_ID | STACK_NAME>   The name or unique stack ID of the stack.
#?
function event () {
    local OPTIND OPTARG opt

    local error stack_name

    while getopts e opt; do
        case $opt in
            e)
                error=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    stack_name=${1:?}

    function __event__ () {
        aws cloudformation describe-stack-events --stack-name "$stack_name"
    }
    
    local -r error_match_options=( -B1 -A7 '(CREATE_FAILED|UPDATE_FAILED)' )

    if [[ $error -eq 1 ]]; then
        __event__ | egrep "${error_match_options[@]}" || :
    else
        __event__
    fi

    unset -f __event__
}
