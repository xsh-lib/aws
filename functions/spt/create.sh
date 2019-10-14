#? Description:
#?   Create support case.
#?   AWS Premium Support Subscription is required to use this service.
#?
#? Usage:
#?   @create
#?     -j <SUBJECT>
#?     -b <BODY>
#?     -s <SERVICE_CODE>
#?     [-c <CATEGORY_CODE>]
#?     [-l <LANGUAGE>]
#?     [-t <ISSUE_TYPE>]
#?
#? Options:
#?     -j <SUBJECT>
#?     -b <BODY>
#?     -s <SERVICE_CODE>
#?     [-c <CATEGORY_CODE>]
#?     [-l <LANGUAGE>]
#?     [-t <ISSUE_TYPE>]
#?
#? Options:
#?   -j <SUBJECT>           The title of the AWS Support case.
#?   -b <BODY>              The communication body text when you create an AWS
#?                          Support case.
#?   -s <SERVICE_CODE>      The code for the AWS service returned by the call to
#?                          describe-services.
#?   [-c <CATEGORY_CODE>]   The category of problem for the AWS Support case.
#?   [-l <LANGUAGE>]        The ISO 639-1 code for the language in which AWS provides support.
#?                          AWS Support currently supports English ("en") and Japanese ("ja").
#?                          The default is English ("en").
#?   [-t <ISSUE_TYPE>]      The type of issue for the case. You can specify either
#?                          "customer-service" or "technical".
#?                          The default is "technical"
#?
function create () {
    local OPTIND OPTARG opt

    local subject body service_code category_code \
          lang=en issue_type=technical

    while getopts j:b:s:c:l:t: opt; do
        case $opt in
            j)
                subject=${OPTARG:?}
                ;;
            b)
                body=${OPTARG:?}
                ;;
            s)
                service_code=${OPTARG:?}
                ;;
            c)
                category_code=${OPTARG:?}
                ;;
            l)
                lang=${OPTARG:?}
                ;;
            t)
                issue_type=${OPTARG:?}
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
        --service-code "${service_code:?}" \
        --category-code "$category_code" \
        --language "${lang:?}" \
        --issue-type "${issue_type:?}"
}
