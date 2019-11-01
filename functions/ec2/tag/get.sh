#? Description:
#?   Get EC2 resource's tag value by tag name.
#?
#? Usage:
#?   @get
#?     [-r REGION]
#?     -i RESOURCE_ID
#?     -t TAG
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -i RESOURCE_ID
#?
#?   EC2 resource identifier.
#?
#?   -t TAG
#?
#?   Tag name.
#?
function get () {
    declare OPTIND OPTARG opt
    declare -a region_opt

    declare resource_id tag

    while getopts r:i:t: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            i)
                resource_id=$OPTARG
                ;;
            t)
                tag=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    aws "${region_opt[@]}" \
        --query 'Tags[].Value' \
        --output text \
        ec2 describe-tags \
        --filters Name=resource-id,Values="$resource_id" Name=tag-key,Values="$tag"
}
