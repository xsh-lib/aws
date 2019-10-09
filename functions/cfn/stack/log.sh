#? Description:
#?   Get console log of EC2 instance of CloudFormation stack.
#?
#? Usage:
#?   @log [-w] <STACK_NAME> <LOGICAL_ID>
#?
#? Options:
#?   [-w]           Wait the instance being running status.
#?   <STACK_NAME>   Stack name.
#?   <LOGICAL_ID>   Logical identifier of EC2 instance in the stack.
#?
function log () {
    local OPTIND OPTARG opt
    local wait stack_name logical_id

    while getopts w opt; do
        case $opt in
            w)
                wait=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    stack_name=${1:?}
    logical_id=${2:?}

    # Constant
    local -r AWS_EC2='AWS::EC2::Instance'

    local json=$(xsh aws/cfn/stack/resource/desc "$stack_name" "$logical_id")
    local type physical_id

    if [[ -n $json ]]; then
        type=$(xsh /json/parser get "$json" StackResourceDetail.ResourceType)

        if [[ $type != $AWS_EC2 ]]; then
            xsh log error "the resource is not EC2 type: $type: $logical_id"
            return 255
        fi

        physical_id=$(xsh /json/parser get "$json" StackResourceDetail.PhysicalResourceId)
    else
        xsh log error "not found resource: $logical_id in the stack: $stack_name"
        return 255
    fi

    if [[ -n $physical_id ]]; then
        xsh /ec2/log ${wait//1/-w} "$physical_id"
    fi
}
