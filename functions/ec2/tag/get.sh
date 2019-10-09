#? Description:
#?   Get EC2 resource's tag value by tag name.
#?
#? Usage:
#?   @get <RESOURCE_ID> <TAG>
#?
#? Options:
#?   <RESOURCE_ID>   EC2 resource identifier.
#?   <TAG>           Tag name.
#?
function get () {
    local resource_id=${1:?}
    local name=${2:?}

    aws ec2 describe-tags \
        --filters Name=resource-id,Values="$resource_id" Name=tag-key,Values="$name" \
        --query 'Tags[0].Value' \
        --output text
}
