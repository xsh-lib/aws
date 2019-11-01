#? Description:
#?   Send email through AWS SES CLI.
#?
#? Usage:
#?   @send
#?     [-r REGION]
#?     -d <DOMAIN>
#?     -t <TO>
#?     [-f FROM]
#?     [-s SUBJECT]
#?     [-b BODY]
#?
#? Options:
#?   [-r REGION]   Use the given region.
#?                   * us-east-1
#?                   * us-west-2
#?                   * eu-west-1
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   -d <DOMAIN>   The domain to be used.
#?
#?   -t <TO>       The email addresses of the primary recipients. You can
#?                 specify multiple recipients as space-separated values.
#?
#?   [-f FROM]     The email address that is sending the email.
#?                 This email address must be either individually verified with Amazon
#?                 SES, or from a domain that has been verified with Amazon SES.
#?                 The default is `no-reply@<yourdomain.com>`.
#?
#?   [-s SUBJECT]  The subject of the message.
#?                 The default is `aws/ses/send test email`.
#?
#?   [-b BODY]     The raw text body of the message.
#?                 The default is `aws/ses/send test email`.
#?
function send () {
    local OPTIND OPTARG opt

    local -a region_opt
    local domain to from

    # set default
    local subject='@send test email'
    local body='This is a test email sent through awscli.'

    while getopts r:d:t:f:s:b: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            d)
                domain=$OPTARG
                ;;
            t)
                to=$OPTARG
                ;;
            f)
                from=$OPTARG
                ;;
            s)
                subject=$OPTARG
                ;;
            b)
                body=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $from ]]; then
        from=no-reply@${domain:?}
    fi

    aws "${region_opt[@]}" ses send-email \
        --from "${from:?}" \
        --to "${to:?}" \
        --subject "$subject" \
        --text "$body"
}
