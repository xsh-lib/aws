#? Description:
#?   Delete inline policies for IAM user.
#?
#? Usage:
#?   @delete
#?     -u USERNAME
#?     [-n POLICY_NAME] [...]
#?
#? Options:
#?   -u USERNAME
#?
#?   The name of the user to associate the policy with.
#?
#?   [-n POLICY_NAME] [...]
#?
#?   The name of the policy document.
#?   This option can be used multiple times.
#?   If not specified, all inline policies for the user are deleted.
#?
function delete () {
    local OPTIND OPTARG opt

    local -a options policy_names
    while getopts u:n: opt; do
        case $opt in
            u)
                options=(--user-name "$OPTARG")
                ;;
            n)
                policy_names+=("$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ ${#policy_names[@]} -eq 0 ]]; then
        xsh log info "collecting attached policies."
        policy_names=( $(aws --query 'PolicyNames[*]' \
                             --output text \
                             iam list-user-policies "${options[@]}") )
    fi

    local name
    for name in "${policy_names[@]}"; do
        xsh log info "$name: deleting policy."
        aws iam delete-user-policy "${options[@]}" --policy-name "$name"
    done
}
