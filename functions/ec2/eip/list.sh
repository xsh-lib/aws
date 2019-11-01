#? Description:
#?   List EC2 Elastic IPs.
#?
#? Usage:
#?   @list
#?     [-a | -u]
#?     [-r REGION]
#?     [-o json | text | table]
#?
#? Options:
#?   [-a]
#?
#?   List associated EIPs only.
#?
#?   [-u]
#?
#?   List unassociated EIPs only.
#?
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-o json | text | table]
#?
#?   The formatting style for command output.
#?   The default is `json`.
#?
function list () {
    local OPTIND OPTARG opt

    local -a region_opt output
    local associated

    while getopts aur:o: opt; do
        case $opt in
            a)
                associated=1
                ;;
            u)
                associated=0
                ;;
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            o)
                output=(--output "$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    local query
    case $associated in
        1)
            # associated EIPs only
            query="Addresses[?InstanceId==*].PublicIp"
            ;;
        0)
            # unassociated EIPs only
            query="Addresses[?InstanceId==null].PublicIp"
            ;;
        '')
            # all EIPs
            query="Addresses[*].PublicIp"
            ;;
        *)
            return 255
            ;;
    esac

    aws "${region_opt[@]}" --query "$query" "${output[@]}" \
        ec2 describe-addresses
}
