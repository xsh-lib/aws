#? Description:
#?   Describe CloudFormation stack resource.
#?
#? Usage:
#?   @desc
#?     [-r REGION]
#?     -s <STACK_NAME | STACK_ID>
#?     -l <RESOURCE_LOGICAL_ID>
#?     [-f FILTER] [...]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -s <STACK_NAME | STACK_ID>
#?
#?   The name or unique stack ID of the stack that is describing.
#?
#?   -l <RESOURCE_LOGICAL_ID>
#?
#?   The logical id of resource.
#?
#?   [-f FILTER] [...]
#?
#?   The filters, syntax: `NAME=VALUE`.
#?   The valid NAME and VALUE, see the `--filters` section of `aws ec2 describe-instances help`.
#?   This option can be used multiple times to narrow results.
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
    declare OPTIND OPTARG opt
    declare -a filters query output

    while getopts r:s:l:f:q:o: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            s)
                stack_name=$OPTARG
                ;;
            l)
                logical_id=$OPTARG
                ;;
            f)
                filters+=("Name=${OPTARG%%=*},Values=${OPTARG#*=}")
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

    if [[ ${#filters} -gt 0 ]]; then
        filters=(--filters "${filters[@]}")
    fi
    
    aws "${region_opt[@]}" "${query[@]}" "${output[@]}" \
        cloudformation describe-stack-resource \
        "${filters[@]}" \
        --stack-name "$stack_name" \
        --logical-resource-id "$logical_id"
}
