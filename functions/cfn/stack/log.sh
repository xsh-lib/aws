#? Description:
#?   Get console log of EC2 instance of CloudFormation stack.
#?
#? Usage:
#?   @log [-r REGION] [-w] -s STACK_NAME -l LOGICAL_ID
#?
#? Options:
#?   [-r REGION]     Region name.
#?                   Defalt is to use the region in your AWS CLI profile.
#?   [-w]            Wait the instance being running status.
#?   -s STACK_NAME   Stack name.
#?   -l LOGICAL_ID   Logical identifier of EC2 instance in the stack.
#?
function log () {
    declare OPTIND OPTARG opt

    declare -a region_opt
    declare wait stack_name logical_id

    while getopts r:ws:l: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            w)
                wait=1
                ;;
            s)
                stack_name=$OPTARG
                ;;
            l)
                logical_id=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    declare physical_id
    physical_id=$(xsh aws/cfn/stack/resource/desc \
                      "${region_opt[@]}" \
                      -q StackResourceDetail.PhysicalResourceId \
                      -o text \
                      -s "$stack_name" \
                      -l "$logical_id")

    if [[ -z $physical_id ]]; then
        xsh log error "$logical_id: the resource is not found in the stack: $stack_name"
        return 255
    else
        xsh aws/ec2/log "${region_opt[@]}" ${wait//1/-w} -i "$physical_id"
    fi
}
