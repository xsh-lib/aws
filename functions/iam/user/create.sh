#? Description:
#?   Create an IAM user.
#?
#? Usage:
#?   @create
#?     [-q QUERY]
#?     [-o json | text | table]
#?     USERNAME
#?
#? Options:
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
#?   USERNAME
#?
#?   IAM username.
#?
function create () {
    local OPTIND OPTARG opt
    local -a query output

    while getopts q:o: opt; do
        case $opt in
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
    shift $((OPTIND - 1))

    aws "${query[@]}" "${output[@]}" iam create-user --user-name "${1:?}"
}
