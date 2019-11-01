#? Description:
#?   Move the account out of AWS SES sandbox by creating support case.
#?
#? Usage:
#?   @move [-r REGION]
#?
#? Options:
#?   [-r REGION]   Move out for the given region.
#?                   * us-east-1
#?                   * us-west-2
#?                   * eu-west-1
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#? @xsh /trap/err -e
#? @subshell
#?
function move () {
    declare OPTIND OPTARG opt

    declare region
    declare -a region_opt
    while getopts r: opt; do
        case $opt in
            r)
                region=$OPTARG
                region_opt=(-r "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $region ]]; then
        region=$(aws configure get default.region)
    fi

    printf "checking if this account is inside SES sandbox ... "

    if xsh aws/ses/sandbox/inside "${region_opt[@]}"; then
        # inside sandbox
        printf "[yes]\n" | xsh /file/mark
    else
        # outside sandbox
        printf "[no]\n" | xsh /file/mark
        return
    fi

    printf "checking if this account is able to create support case over CLI ... "

    if xsh aws/spt/is-callable; then
        # callable
        printf "[yes]\n" | xsh /file/mark
        printf "checking if there is an existing support case ... "

        if [[ -n $case_id ]]; then
            # there is a case
            printf "[yes]\n" | xsh /file/mark
            printf "checking the support case status ... "

            declare status
            status=$(aws --region us-east-1 \
                         --query '[].status' \
                         support describe-cases \
                         --case-id-list "$case_id" \
                         --include-resolved-cases)

            printf "[%s]\n" "$status" | xsh /file/mark

            if [[ $status == Resolved ]]; then
                printf 'continue to recheck the sandbox status.\n'
            else
                printf 'please wait for the support case to be resolved, then continue.\n'
            fi
        else
            # there is no case
            printf "[no]\n" | xsh /file/mark

            if xsh /io/confirm -m 'shall I create a support case for you?'; then
                declare -a body
                body+=("Limit increase request 1")
                body+=("Service: SES Sending Limits")
                body+=("Region: $region")
                body+=("Limit name: Desired Daily Sending Quota")
                body+=("New limit value: 1000")
                body+=("------------")
                body+=("Limit increase request 2")
                body+=("Service: SES Sending Limits")
                body+=("Region: $region")
                body+=("Limit name: Desired Maximum Send Rate")
                body+=("New limit value: 10")
                body+=("------------")
                body+=("Use case description: My service needs to move my account out of the SES sandbox.")
                body+=("Mail Type: System Notifications")
                body+=("My email-sending complies with the <a href=\"http://aws.amazon.com/service-terms/\" target=\"_blank\">AWS Service Terms</a> and <a href=\"http://aws.amazon.com/aup/\" target=\"_blank\">AUP</a>: Yes")
                body+=("I only send to recipients who have specifically requested my mail: Yes")
                body+=("I have a process to handle bounces and complaints: Yes")

                declare case_id
                case_id=$(xsh aws/spt/create \
                    -j "Limit Increase: SES Sending Limits" \
                    -b "$(printf '%s\n' "${body[@]}")" \
                    -s ses \
                    -c "Service Limit Increase, SES Sending Limits" \
                    -l en)
            fi
        fi
    else
        # not callable
        printf "[no]\n" | xsh /file/mark

        declare -a msg
        msg+=("go to below URL to create a support case to move your account out of AWS SES sandbox:")
        msg+=("  * https://aws.amazon.com/ses/extendedaccessrequest/")
        msg+=("here's the help document about how to create this case:")
        msg+=("  * https://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html")
        msg+=("if your account is still in the Amazon SES sandbox, you may only send to verified addresses")
        msg+=("or domains, or to email addresses associated with the Amazon SES Mailbox Simulator.")

        printf '%s\n' "${msg[@]}"
    fi

    read -n 1 -s -p "press any key to continue, CTRL-C to exit."
    printf '\n\n'
    @move "${region_opt[@]}"
}
