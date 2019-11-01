#? Description:
#?   Adds a domain to the list of identities of your SES service and attempts to verify it.
#?
#? Usage:
#?   @domain-identity [-r REGION] <DOMAIN>
#?
#? Options:
#?   [-r REGION]   Add the domain to the given region.
#?                   * us-east-1
#?                   * us-west-2
#?                   * eu-west-1
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   <DOMAIN>      The domain to be verified.
#?
#? Return:
#?   0: Verified
#?   != 0: Not verified
#?
#？Link:
#?   https://docs.aws.amazon.com/general/latest/gr/rande.html#ses_region
#?
#? @xsh /trap/err -e
#? @subshell
#?
function domain-identity () {

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
    shift $((OPTIND - 1))
    declare domain=${1:?}

    printf "checking the verifying status of $domain ... "

    aws "${region_opt[@]}" ses verify-domain-identity --domain "$domain" >/dev/null

    declare out status

    out=$(aws "${region_opt[@]}" ses get-identity-verification-attributes --identities "$domain")
    status=$(xsh /json/parser eval "$out" '{JSON}["VerificationAttributes"]["'$domain'"]["VerificationStatus"]')

    declare text="\
    * Record Type: TXT (Text)
    * TXT Name*: _amazonses.%s
    * TXT Value: %s\n"

    if [[ $status == Success ]]; then
        printf '[%s]\n' yes | xsh /file/mark
    else
        printf '[%s]\n' no | xsh /file/mark
        printf "add below DNS record to the domain:\n\n"

        declare txt_value
        txt_value=$(xsh /json/parser eval "$out" '{JSON}["VerificationAttributes"]["'$domain'"]["VerificationToken"]')
        printf "$text\n" "$domain" "$txt_value"

        printf "then grab some coffee, it takes time for the DNS to take effect across the internet.\n"
        printf "please wait "

        declare ret=1
        while [[ $ret -ne 0 ]]; do
            printf '.'
            # identity-exists: check every 3 seconds, exit after 20 failed checks
            aws "${region_opt[@]}" ses wait identity-exists --identities "$domain" >/dev/null 2>&1 && ret=$? || ret=$?
        done

        printf "\ndomain $domain has been verified by AWS SES.\n"
    fi
}
