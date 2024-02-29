#? Description:
#?   List AWS CloudFormation stacks.
#?
#? Usage:
#?   @list
#?     [-r REGION]
#?     [-s STATUS ...]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-s STATUS ...]
#?
#?   Filter stacks by using --stack-status-filter.
#?   The default is to list all stacks.
#?
#?   [-q QUERY]
#?
#?   A JMESPath query to use in filtering the response data.
#?   See spec of JMESPath: http://jmespath.org/specification.html
#?   Give the query without the part: `StackSummaries`.
#?
#?   [-o json | text | table]
#?
#?   The formatting style for command output.
#?   The default is `json`.
#?
#? Example:
#?   # List all stacks which are in serviceable status and whose name starts with `foo`.
#?   $ @list -s "${XSH_AWS_CFN__STACK_STATUS_SERVICEABLE[@]}" -q "[?starts_with(StackName, 'foo')]"
#?
function list () {
    declare OPTIND OPTARG opt

    declare -a region_opt status query output

    xsh imports /util/getopts/extra

    while getopts r:s:q:o: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            s)
                x-util-getopts-extra "$@"
                # shellcheck disable=SC2207
                status=(--stack-status-filter "${OPTARG[@]:?]}")
                ;;
            q)
                # the selector `|[]` strips the outer layer of `[]` in the result
                # and if the result list is empty, won't give a literal null.
                query=(--query "StackSummaries${OPTARG:?}")
                ;;
            o)
                output=(--output "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done

    # list stacks
    aws "${region_opt[@]}" "${query[@]}" "${output[@]}" \
        cloudformation list-stacks \
        "${status[@]}"
}
