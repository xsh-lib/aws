#? Description:
#?   Create tag on EC2 resource.
#?
#? Usage:
#?   @create
#?     [-r REGION]
#?     -i RESOURCE_ID
#?     -t TAG
#?     -v VALUE
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
#?   -v VALUE
#?
#?   Tag value.
#?
function create () {
    local OPTIND OPTARG opt
    local -a region_opt
    local resource_id tag value

    while getopts r:i:t:v: opt; do
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
            v)
                value=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    aws "${region_opt[@]}" ec2 create-tags \
        --resource "$resource_id" \
        --tags Key="$tag",Value="$value"
}
