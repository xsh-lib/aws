#? Descriptions:
#?   Maintain RDS instance publicly accessible status.
#?
#? Usage:
#?   @access [-r REGION] [-i <INSTANCE_ID>] [-s <on | off>]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-i INSTANCE_ID]
#?
#?   RDS instance identifier.
#?   If omitted, will show current status for all instances.
#?
#?   [-s <on | off>]
#?
#?   Turn on or off the publicly accessible status for the given instance.
#?   Option -i is required with -s.
#?   If omitted, will show current status for the given instance.
#?
function access () {
    declare OPTIND OPTARG opt
    declare -a region_opt
    declare instance_id status

    while getopts r:i:s: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            i)
                instance_id=$OPTARG
                ;;
            s)
                status=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ $status == on ]]; then
        aws "${region_opt[@]}" \
            rds modify-db-instance --db-instance-identifier "${instance_id:?}" \
            --publicly-accessible
    elif [[ $status == off ]]; then
        aws "${region_opt[@]}" \
            rds modify-db-instance --db-instance-identifier "${instance_id:?}" \
            --no-publicly-accessible
    elif [[ -n $instance_id ]]; then
        aws "${region_opt[@]}" \
            --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,PubliclyAccessible:PubliclyAccessible}' \
            --output text \
            rds describe-db-instances --db-instance-identifier "${instance_id:?}"
    else
        aws "${region_opt[@]}" \
            --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,PubliclyAccessible:PubliclyAccessible}' \
            --output text \
            rds describe-db-instances
    fi
}
