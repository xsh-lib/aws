#? Description:
#?   Create access key.
#?
#? Usage:
#?   @create
#?     [-u USERNAME]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   [-u USERNAME]
#?
#?   Create access keys for the IAM user.
#?   If not specified, the USERNAME is determined implicitly based on the AWS access
#?   key ID used to sign the request. Consequently, you can use this operation to
#?   manage AWS account root user credentials even if the AWS account has no
#?   associated users.
#?
#?   [-q QUERY]
#?
#?   A JMESPath query to use in filtering the response data.
#?   See spec of JMESPath: http://jmespath.org/specification.html
#?
#?   [-o json | text | table]
#?
#?   The formatting style for command output.
#?   The default is `json`.
#?
#? Example:
#?   $ @create -q '[AccessKey.AccessKeyId,AccessKey.SecretAccessKey]' -o text
#?   AKIATJUQGF6OAGD4YK4O	TSLZk1KrPpDlYLCFRijTHY5uIyezn3FDRuUZGmNl
#?
function create () {
    declare OPTIND OPTARG opt

    declare -a options query output
    while getopts u:q:o: opt; do
        case $opt in
            u)
                options=(--user-name "$OPTARG")
                ;;
            q)
                query=(--query "$OPTARG")
                ;;
            o)
                output=(--output "$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    aws "${query[@]}" "${output[@]}" iam create-access-key "${options[@]}"
}
