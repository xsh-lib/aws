#? Description:
#?   Delete access keys.
#?   If called without any option, all access keys of requesting user are deleted.
#?
#? Usage:
#?   @delete
#?     [-u USERNAME]
#?     [-i ACCESS_KEY_ID] [...]
#?
#? Options:
#?   [-u USERNAME]
#?
#?   Delete access keys for the IAM user.
#?   If not specified, the USERNAME is determined implicitly based on the AWS access
#?   key ID used to sign the request. Consequently, you can use this operation to
#?   manage AWS account root user credentials even if the AWS account has no
#?   associated users.
#?
#?   [-i ACCESS_KEY_ID] [...]
#?
#?   Delete the given access key for user.
#?   This option can be used multiple times.
#?   If not specified, all access keys for the user are deleted.
#?
function delete () {
    local OPTIND OPTARG opt

    local -a options access_key_ids
    while getopts u:i: opt; do
        case $opt in
            u)
                options=(--user-name "$OPTARG")
                ;;
            i)
                access_key_ids+=("$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ ${#access_key_ids[@]} -eq 0 ]]; then
        xsh log info "collecting access keys."
        access_key_ids=( $(aws --query 'AccessKeyMetadata[*].AccessKeyId' \
                               --output text \
                               iam list-access-keys "${options[@]}") )
    fi

    local id
    for id in "${access_key_ids[@]}"; do
        xsh log info "$id: deleting access key."
        aws iam delete-access-key "${options[@]}" --access-key-id "$id"
    done
}
