#? Description:
#?   Create snapshot for EC2 EBS volume.
#?
#? Usage:
#?   @create <RESOURCE_ID> <TAG>
#?
#? Options:
#?   <RESOURCE_ID>   EC2 resource identifier.
#?   <TAG>           Tag name to create.
#?
function create () {
    local resource_id=${1:?}
    local name=${2:?}

    aws ec2 create-tags \
        --resource "$resource_id" \
        --tags Key=Name,Value="$name"
}
