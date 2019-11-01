#? Dscription:
#?   Get the status of CloudFormation stack.
#?
#? Usage:
#?   @get [-r REGION] -s <STACK_NAME | STACK_ID>
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -s <STACK_NAME | STACK_ID>
#?
#?   Stack name or stack identifier.
#?
function get () {
    local OPTIND OPTARG opt

    local -a region_opt
    local stack_name

    while getopts r:s: opt; do
        case $opt in
            r)
                region_opt=(-r "${OPTARG:?}")
                ;;
            s)
                stack_name=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    xsh aws/cfn/stack/desc "${region_opt[@]}" -q "Stacks[].StackStatus" -o text -s "$stack_name"
}
