#? Description:
#?   Describe CloudFormation stack.
#?
#? Usage:
#?   @desc
#?     [-r REGION]
#?     [-s STACK_NAME | STACK_ID]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-s STACK_ID | STACK_NAME]
#?
#?   The name or unique stack ID of the stack that is describing.
#?
#?   [-q QUERY]
#?
#?   A JMESPath query to use in filtering the response data.
#?   See spec of JMESPath: http://jmespath.org/specification.html
#?   Give the query without the part: `Reservations[*][]`.
#?
#?   [-o json | text | table]
#?
#?   The formatting style for command output.
#?   The default is `json`.
#?
function desc () {
    local OPTIND OPTARG opt

    local -a region_opt stack_name query output

    while getopts r:s:q:o: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            s)
                stack_name=(--stack-name "$OPTARG")
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

    aws "${region_opt[@]}" "${query[@]}" "${output[@]}" \
        cloudformation describe-stacks "${stack_name[@]}"
}
