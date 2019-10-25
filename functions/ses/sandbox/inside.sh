#? Description:
#?   Check if the SES account is inside sandbox for the given region.
#?
#? Usage:
#?   @inside [-r REGION]
#?
#? Options:
#?   [-r REGION]   Check for the given region.
#?                   * us-east-1
#?                   * us-west-2
#?                   * eu-west-1
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#? Return:
#?   0: Inside sandbox
#?   != 0: Outside sandbox
#?
#？Link:
#?   https://docs.aws.amazon.com/general/latest/gr/rande.html#ses_region
#?
#? @xsh /trap/err -e
#? @subshell
#?
function inside () {
    local OPTIND OPTARG opt

    local region
    while getopts r: opt; do
        case $opt in
            r)
                region=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done
 
    local -a options
    if [[ -n $region ]]; then
        options=(--region "$region")
    fi

    local out max24hoursend

    # do not double quote ${options[@]}
    out=$(aws ${options[@]} ses get-send-quota)
    max24hoursend=$(xsh /json/parser get "$out" Max24HourSend)

    test "$max24hoursend" == 200.0
}
