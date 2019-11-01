#? Dscription:
#?   Wait CloudFormation stack come to an expected final status.
#?
#? Usage:
#?   @wait [-r REGION] [-w TIMEOUT] [-i INTERVAL] -S STATUS -s <STACK_NAME | STACK_ID>
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-w TIMEOUT]
#?
#?   Timeout in seconds.
#?   Default is 1200 seconds (20 minutes).
#?
#?   [-i INTERVAL]
#?
#?   Interval in seconds to check status.
#?   Default is 30 seconds.
#?
#?   -S STATUS
#?
#?   Expected final status.
#?   Return error if the stack status dosn't match the expected status.
#?
#?   This option is case insensitive.
#?   This option supports regex, e.g.: `*_COMPLETE`.
#?
#?   -s <STACK_NAME | STACK_ID>
#?
#?   Stack name or stack identifier.
#?
#? @xsh /trap/err -e
#? @subshell
#?
function wait () {
    declare OPTIND OPTARG opt

    declare -a region_opt
    declare target_status timeout=1200 interval=30 stack_name

    while getopts r:w:i:S:s: opt; do
        case $opt in
            r)
                region_opt=(-r "${OPTARG:?}")
                ;;
            w)
                timeout=${OPTARG:?}
                ;;
            i)
                interval=${OPTARG:?}
                ;;
            S)
                target_status=${OPTARG:?}
                ;;
            s)
                stack_name=${OPTARG:?}
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $target_status || -z $stack_name ]]; then
        xsh log error "parameter null or not set."
        return 255
    fi

    printf "expecting status: %s - timeout: %s seconds - interval: %s seconds.\n" \
           "$target_status" "$timeout" "$interval"

    declare timeout_epoch
    timeout_epoch=$(($(date +%s) + timeout))

    declare status left_epoch
    while [[ 1 ]]; do
        status=$(xsh aws/cfn/stack/status/get "${region_opt[@]}" -s "$stack_name")
        printf "%s: %s ..." "$(date '+%F %T')" "${status:-NULL}"

        left_epoch=$((timeout_epoch - $(date +%s)))

        # exit loop if match expecting status
        if [[ $status == $target_status ]]; then
            printf " [ok]\n"
            return
        # exit loop if reachs final status
        elif [[ -n $(xsh /array/search XSH_AWS_CFN__STACK_FINAL_STATUS "$status") ]]; then
            printf " [not match]\n"
            return 255
        # exit loop if time is out
        elif [[ $left_epoch -lt 0 ]]; then
            printf " time's up - the check is stopped.\n"
            return 255
        else
            printf " timeout in %s seconds ...\n" "$left_epoch"
        fi

        sleep "$interval"
    done
}
