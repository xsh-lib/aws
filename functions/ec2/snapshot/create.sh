#? Description:
#?   Create snapshots for EBS volume of EC2 instances.
#?
#? Usage:
#?   @create
#?     [-n INSTANCE_NAME]
#?     [-i INSTANCE_ID]
#?
#? Options:
#?   [-n INSTANCE_NAME]
#?
#?   EC2 instance tag value for tag 'Name'.
#?
#?   [-i INSTANCE_ID]
#?
#?   EC2 instance identifier.
#?
function create () {
    local OPTIND OPTARG opt

    declare -a instance_names instance_ids
    while getopts n:i: opt; do
        case $opt in
            n)
                instance_names+=( "$OPTARG" )
                ;;
            i)
                instance_ids+=( "$OPTARG" )
                ;;
            *)
                return 255
                ;;
        esac
    done

    declare -a volume_ids

    # By tag Names
    if [[ -n ${instance_names[@]} ]]; then
        local comma_list="$(echo "${instance_names[@]}" | sed 's/ /,/g')"
        volume_ids+=(
            "$(aws ec2 describe-instances \
                  --filters Name=tag:Name,Values=${comma_list:?} \
                  --query "Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" \
                  --output text
            )"
        )
    fi

    # By instance IDs
    if [[ -n ${instance_ids[@]} ]]; then
        volume_ids+=(
            "$(aws ec2 describe-instances \
                  --instance-ids "${instance_ids[@]}" \
                  --query "Reservations[*].Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" \
                  --output text
            )"
        )
    fi

    local volume_id
    for volume_id in "${volume_ids[@]}"; do
        xsh aws/ec2/snapshot/create "${volume_id:?}"
    done
}
