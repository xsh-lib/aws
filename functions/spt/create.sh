#? Description:
#?   Create support case.
#?   AWS Premium Support Subscription is required to use this service.
#?   This util is untested!!!
#?
#? Usage:
#?   @create
#?     -j <SUBJECT>
#?     -b <BODY>
#?     [-s <SERVICE_CODE>]
#?     [-c <CATEGORY_CODE>]
#?     [-l <LANGUAGE>]
#?     [-t <ISSUE_TYPE>]
#?     [-e <CC_EMAIL>] [...]
#?
#? Options:
#?   -j <SUBJECT>           The title of the AWS Support case.
#?   -b <BODY>              The communication body text when you create an AWS
#?                          Support case.
#?   [-s <SERVICE_CODE>]    The code for the AWS service returned by the call to
#?                          describe-services.
#?   [-c <CATEGORY_CODE>]   The category of problem for the AWS Support case.
#?   [-l <LANGUAGE>]        The ISO 639-1 code for the language in which AWS provides support.
#?                          AWS Support currently supports English ("en") and Japanese ("ja").
#?   [-t <ISSUE_TYPE>]      The type of issue for the case. You can specify either
#?                          "customer-service" or "technical".
#?                          The default is "technical".
#?   [-e <CC_EMAIL>]        Email addresses to cc to.
#?                          Use multiple -e to specify multiple Email addresses.
#?
#? Output:
#?   The AWS Support case ID requested or returned in the call.
#?
function create () {
    declare OPTIND OPTARG opt

    declare subject body
    declare -a options

    while getopts j:b:s:c:l:t:e: opt; do
        case $opt in
            j)
                subject=${OPTARG:?}
                ;;
            b)
                body=${OPTARG:?}
                ;;
            s)
                options+=(--service-code "${OPTARG:?}")
                ;;
            c)
                options+=(--category-code "${OPTARG:?}")
                ;;
            l)
                options+=(--language "${OPTARG:?}")
                ;;
            t)
                options+=(--issue-type "${OPTARG:?}")
                ;;
            e)
                options+=(--cc-email-addresses "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done

    # aws support command is availble only in region us-east-1 by now.
    # https://docs.aws.amazon.com/general/latest/gr/rande.html#awssupport_region
    aws --region us-east-1 \
        support create-case \
        --subject "${subject:?}" \
        --communication-body "${body:?}" \
        --output text
        "${options[@]}" \
}
