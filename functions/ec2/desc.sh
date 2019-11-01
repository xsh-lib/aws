#? Description:
#?   Describe EC2 instances.
#?
#? Usage:
#?   @desc
#?     [-i INSTANCE_ID] [...]
#?     [-r REGION]
#?     [-f FILTER] [...]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   [-i INSTANCE_ID] [...]
#?
#?   EC2 instance identifier.
#?
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
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
#? Example:
#?   # list unteminated instances, output public IP address and the tag value of `Name`
#?   $ @desc -f instance-state-name=pending,running,stopping,stopped \
#?           -q "Instances[*].[PublicIpAddress,Tags[?Key=='Name'].Value]"
#?   [
#?       [
#?           [
#?               "54.180.56.131",
#?               [
#?                   "MyInstance"
#?               ]
#?           ]
#?       ]
#?   ]
#?
#?   # list unteminated instances, output public IP address and the value of tag `Name`,
#?   # filter out the instances without a tag `Name` or wihtout a value for tag `Name`,
#?   # the `[]` around the tag is stripped.
#?   $ @desc -f instance-state-name=pending,running,stopping,stopped \
#?           -f 'tag:Name=*' \
#?           -q "Instances[?not_null(Tags[?Key=='Name'].Value|[0])!=''][PublicIpAddress,Tags[?Key=='Name'].Value|[0]]"
#?   [
#?       [
#?           [
#?               "54.180.56.131",
#?               "VPN-2019E-PROD"
#?           ]
#?       ]
#?   ]
#?
function desc () {
    declare OPTIND OPTARG opt
    declare -a instance_ids region_opt filters query output

    while getopts i:r:f:q:o: opt; do
        case $opt in
            i)
                instance_ids+=("$OPTARG")
                ;;
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            f)
                filters+=("Name=${OPTARG%%=*}")
                filters+=("Values=${OPTARG#*=}")
                ;;
            q)
                # the selector `|[]` strips the outer layer of `[]` in the result
                # and if the result list is empty, won't give a literal null.
                query=(--query "Reservations[*].[$OPTARG]|[]")
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
        filters=(--filters "$(IFS=$','; echo "${filters[*]}")")
    fi

    if [[ ${#instance_ids} -gt 0 ]]; then
        instance_ids=(--instance-ids "${instance_ids[*]}")
    fi

    aws "${region_opt[@]}" "${query[@]}" "${output[@]}" \
        ec2 describe-instances "${instance_ids[@]}" "${filters[@]}"
}
