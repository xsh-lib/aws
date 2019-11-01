#? Description:
#?   Generate domain DKIM token for SES service and attempts to verify it.
#?
#? Usage:
#?   @domain-dkim [-r REGION] <DOMAIN>
#?
#? Options:
#?   [-r REGION]   Generate DKIM token in the given region.
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
function domain-dkim () {
    declare OPTIND OPTARG opt

    declare -a region_lopt region_sopt
    while getopts r: opt; do
        case $opt in
            r)
                region_lopt=(--region "${OPTARG:?}")
                region_sopt=(-r "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    declare domain=${1:?}

    printf "checking the DKIM verifying status of $domain ... "

    aws "${region_lopt[@]}" ses verify-domain-dkim --domain "$domain" >/dev/null

    declare out status

    out=$(aws "${region_lopt[@]}" ses get-identity-dkim-attributes --identities "$domain")
    status=$(xsh /json/parser eval "$out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimVerificationStatus"]')

    declare text="\
    * Record Type: CNAME
    * Name: %s._domainkey.%s
    * Value: %s.dkim.amazonses.com\n"

    if [[ $status == Success ]]; then
        printf '[%s]\n' yes | xsh /file/mark
    else
        printf '[%s]\n' no | xsh /file/mark
        printf "add below DNS record to the domain:\n\n"

        declare -a tokens
        declare i
        for i in {0..2}; do
            tokens[$i]=$(xsh /json/parser eval "$out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimTokens"]['$i']')
        done

        declare token
        for token in "${tokens[@]}"; do
            printf "$text\n" "$token" "$domain" "$token"
        done

        printf "then grab some coffee, it takes time for the DNS to take effect across the internet.\n"

        read -n 1 -s -p "press any key to continue, CTRL-C to exit."
        printf '\n\n'
        @domain-dkim "${region_sopt[@]}" "$domain"
    fi
}
