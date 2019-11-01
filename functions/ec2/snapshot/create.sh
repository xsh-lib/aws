#? Description:
#?   Create snapshots for EBS volume of EC2 instances.
#?
#? Usage:
#?   @create
#?     [-r REGION]
#?     [-n INSTANCE_NAME] [...]
#?     [-i INSTANCE_ID] [...]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-n INSTANCE_NAME] [...]
#?
#?   EC2 instance tag value for tag `Name`.
#?
#?   [-i INSTANCE_ID] [...]
#?
#?   EC2 instance identifier.
#?
function create () {
    declare OPTIND OPTARG opt
    declare -a region_opt instance_names instance_ids

    while getopts r:n:i: opt; do
        case $opt in
            r)
                region_opt=(-r "${OPTARG:?}")
                ;;
            n)
                instance_names+=("$OPTARG")
                ;;
            i)
                instance_ids+=("$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    declare -a volume_ids

    # by tag Names
    if [[ ${#instance_names[@]} -gt 0 ]]; then
        declare csv_names
        csv_names=$(IFS=,; echo "${instance_names[*]}")

        # collect volume
        volume_ids+=(
            $(xsh aws/ec2/desc \
                  "${region_opt[@]}" \
                  -f "tag:Name=${csv_names:?}" \
                  -q "Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" \
                  -o text
            )
        )
    fi

    # by instance IDs
    if [[ ${#instance_ids[@]} -gt 0 ]]; then
        # collect volume
        volume_ids+=(
            $(xsh aws/ec2/desc \
                  "${region_opt[@]}" \
                  -i "${instance_ids[*]}" \
                  -q "Instances[*].BlockDeviceMappings[*].Ebs.VolumeId" \
                  -o text
            )
        )
    fi

    declare volume_id
    for volume_id in "${volume_ids[@]}"; do
        # create snapshot
        xsh aws/ec2/volume/snapshot/create "${region_opt[@]}" -i "$volume_id"
    done
}
