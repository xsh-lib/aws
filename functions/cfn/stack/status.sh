#? Dscription:
#?   Get the status of CloudFormation stack.
#?
#? Usage:
#?   @status [-s STATUS] [-w TIMEOUT] [-i INTERVAL] <STACK_NAME | STACK_ID>
#?
#? Options:
#?   [-s STATUS]
#?
#?   Expected status.
#?   Return error if the stack status dosn't match the expected status.
#?
#?   This option is case insensitive.
#?   This option supports regex, e.g.: `*_COMPLETE`.
#?
#?   [-w TIMEOUT]
#?
#?   Timeout in seconds.
#?   Block to wait for the expected status.
#?
#?   [-i INTERVAL]
#?
#?   Interval in seconds to check status again.
#?   This option is ignored unless -w is used.
#?   Default interval is 10 seconds.
#?
#?   <STACK_NAME | STACK_ID>
#?
#?   Stack name or stack identifier.
#?
function status () {
    local OPTIND OPTARG opt
    local target_status timeout interval=10

    while getopts s:w:i: opt; do
        case $opt in
            s)
                target_status=$OPTARG
                ;;
            w)
                timeout=$OPTARG
                ;;
            i)
                interval=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    stack_name=${1:?}

    function __aws_cfn_stack_status__ () {
        xsh aws/cfn/stack/desc "$1" | awk -F: '/StackStatus/ {print $2}' | tr -d ' ",'
    }

    function __aws_cfn_stack_is_final_status__ () {
        case "$1" in
            *_COMPLETE)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }

    function __aws_cfn_stack_is_fail_status__ () {
        case "$1" in
            *_FAILED|ROLLBACK_*|DELETE_COMPLETE)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    }

    local msg
    [[ -n $target_status ]] && msg="expecting status $target_status"
    [[ -n $timeout ]] && msg="$msg in $timeout seconds, check interval is $interval seconds."
    if [[ -n $msg ]]; then
        xsh log info "$msg" >&2
    fi

    local status ret=0

    while [[ 1 ]]; do
        status=$(__aws_cfn_stack_status__ "$stack_name") || return
        ret=0

        # exit loop if no target status expected
        if [[ -z $target_status ]]; then
            break
        fi

        # check if match expecting status
        egrep -iq $target_status <<< "$status"
        ret=$?

        # exit loop if not in block mode
        if [[ -z $timeout ]]; then
            break
        fi

        # exit loop if time is out
        if [[ $timeout -le 0 ]]; then
            ret=255
            xsh log warning "time is out, exiting check."
            break
        fi

        # exit loop if reachs failed status
        if __aws_cfn_stack_is_fail_status__ "$status"; then
            ret=255
            break
        fi

        # exit loop if reachs final status
        if __aws_cfn_stack_is_final_status__ "$status"; then
            break
        fi

        xsh log info "$(date): ${status:-NULL}, $timeout seconds left before timeout..." >&2
        timeout=$((timeout - interval))
        sleep $interval
    done

    xsh log info "status: $status" >&2
    xsh log info "return code: $ret" >&2
    echo "$status"

    return $ret
}
