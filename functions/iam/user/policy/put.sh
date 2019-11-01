#? Description:
#?   Add or update an inline policy for IAM user.
#?
#? Usage:
#?   @put
#?     -u USERNAME
#?     -n POLICY_NAME
#?     -d POLICY_DOCUMENT
#?
#? Options:
#?   -u USERNAME
#?
#?   The name of the user to associate the policy with.
#?
#?   -n POLICY_NAME
#?
#?   The name of the policy document.
#?
#?   -d POLICY_DOCUMENT
#?
#?   The policy document.
#?   You must provide policies in JSON format
#?
function put () {
    declare OPTIND OPTARG opt

    declare username policy_name policy_document
    while getopts u:n:d: opt; do
        case $opt in
            u)
                username=$OPTARG
                ;;
            n)
                policy_name=$OPTARG
                ;;
            d)
                policy_document=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    xsh log info "$policy_name: adding/updating policy for $username."
    aws iam put-user-policy \
        --user-name "$username" \
        --policy-name "$policy_name" \
        --policy-document "$policy_document"
}
