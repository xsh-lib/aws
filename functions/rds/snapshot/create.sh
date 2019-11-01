#? Description:
#?   Create snapshots for RDS instances.
#?
#? Usage:
#?   @create
#?     [-r REGION]
#?     [-i INSTANCE_ID] [...]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-i INSTANCE_ID] [...]
#?
#?   EC2 instance identifier.
#?
function create () {
    local OPTIND OPTARG opt
    local -a region_opt instance_ids

    while getopts r:i: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            i)
                instance_ids+=("$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    local instance_id ts
    for instance_id in "${instance_ids[@]}"; do
        ts=$(date '+%Y%m%d-%H%M')

        # creating snapshot
        aws "${region_opt[@]}" \
            rds create-db-snapshot \
            --db-instance-identifier "${instance_id:?}" \
            --db-snapshot-identifier "${instance_id:?}-${ts:?}"
    done
}
