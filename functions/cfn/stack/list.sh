#? Description:
#?   List AWS CloudFormation stacks.
#?
#? Usage:
#?   @list [-r REGION]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
function list () {
    declare OPTIND OPTARG opt

    declare -a region_opt
    while getopts r: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done

    # list stacks
    aws "${region_opt[@]}" cloudformation list-stacks \
        --stack-status-filter "${XSH_AWS_CFN__STACK_STATUS[@]}"
}

