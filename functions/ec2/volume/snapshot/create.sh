#? Description:
#?   Create snapshot for EC2 EBS volume.
#?   The snapshot is tagged after it's created.
#?
#? Usage:
#?   @create
#?     [-r REGION]
#?     -i VOLUME_ID
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -i VOLUME_ID
#?
#?   EBS volume identifier.
#?
#? @xsh /trap/err -e
#? @subshell
#?
function create () {
    declare OPTIND OPTARG opt
    declare -a region_sopt region_lopt
    declare volume_id

    while getopts r:i: opt; do
        case $opt in
            r)
                region_sopt=(-r "${OPTARG:?}")
                region_lopt=(--region "${OPTARG:?}")
                ;;
            i)
                volume_id=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    declare snapshot_id

    # creating snapshot
    printf "creating snapshot for volume: $volume_id ..."
    snapshot_id=$(
        aws "${region_lopt[@]}" \
            --query "SnapshotId" \
            --output text \
            ec2 create-snapshot --volume-id "$volume_id")
    printf " $snapshot_id ... [ok]\n"

    # get the tag `Name` for volume
    declare volume_tag
    volume_tag=$(xsh aws/ec2/tag/get "${region_sopt[@]}" -i "$volume_id" -t Name)

    # get instance id
    declare instance_id
    instance_id=$(
        aws "${region_lopt[@]}" \
            --query "Volumes[].Attachments[].InstanceId" \
            --output text \
            ec2 describe-volumes --volume-ids "$volume_id")

    # get the tag `Name` for instance
    declare instance_tag
    instance_tag=$(xsh aws/ec2/tag/get "${region_sopt[@]}" -i "$instance_id" -t Name)

    # tag the snapshot
    declare ts snapshot_tag
    ts=$(date '+%Y%m%d-%H%M')
    snapshot_tag=${volume_tag:-${instance_tag:-snapshot}}-$ts

    printf "tagging the snapshot: $snapshot_id ..."
    xsh aws/ec2/tag/create "${region_sopt[@]}" -i "$snapshot_id" -t Name -v "$snapshot_tag"
    printf " $snapshot_tag ... [ok]\n"
}
