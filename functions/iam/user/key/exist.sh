#? Description:
#?   Check the existence of access keys.
#?   If called without any option, all access keys of requesting user are checked.
#?
#? Usage:
#?   @exist
#?     [-u USERNAME]
#?     [-i ACCESS_KEY_ID]
#?
#? Options:
#?   [-u USERNAME]
#?
#?   Check access keys for the IAM user.
#?   If not specified, the USERNAME is determined implicitly based on the AWS access
#?   key ID used to sign the request. Consequently, you can use this operation to
#?   manage AWS account root user credentials even if the AWS account has no
#?   associated users.
#?
#?   [-i ACCESS_KEY_ID]
#?
#?   Check the given access key for user.
#?   If not specified, all access keys for the user are checked.
#?
#? Return:
#?   0: yes
#?   1: no
#?
function exist () {
    local OPTIND OPTARG opt

    local -a options query
    while getopts u:i: opt; do
        case $opt in
            u)
                options=(--user-name "$OPTARG")
                ;;
            i)
                query="[?AccessKeyId=='$OPTARG']"
                ;;
            *)
                return 255
                ;;
        esac
    done

    test $(aws --query "length(AccessKeyMetadata$query)" \
               iam list-access-keys "${options[@]}") -gt 0
}
