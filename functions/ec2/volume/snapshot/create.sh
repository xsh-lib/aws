#? Description:
#?   Create snapshot for EC2 EBS volume.
#?
#? Usage:
#?   @create
#?     [-i VOLUME_ID]
#?
#? Options:
#?   [-i VOLUME_ID]
#?
#?   EBS volume identifier.
#?
function create () {
    local volume_id=${1:?}

    # Creating snapshot
    local snapshot_id=$(
        aws ec2 create-snapshot \
            --volume-id "$volume_id" \
            --query "SnapshotId" \
            --output text \
          )

    local tag_name="$(xsh aws/ec2/tag/get "$volume_id" Name)"

    if [[ -n $tag_name && $tag_name != 'None' && -n $snapshot_id ]]; then
        local ts=$(date '+%Y%m%d-%H%M')
        local name="${tag_name:?}-${ts:?}"

        xsh aws/ec2/tag/create "$snapshot_id" "$name"
    fi
}
