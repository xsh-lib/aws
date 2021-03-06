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
    declare OPTIND OPTARG opt

    declare -a region_opt
    while getopts r: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done
 
    declare max24hoursend

    max24hoursend=$(aws "${region_opt[@]}" \
                        --query Max24HourSend --output text \
                        ses get-send-quota)

    test "$max24hoursend" == 200.0
}
