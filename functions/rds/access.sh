#? Descriptions:
#?   Maintain RDS instance publicly accessible status.
#?
#? Usage:
#?   @access [-i <INSTANCE_ID>] [-s <on | off>]
#?
#? Options:
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
    local OPTIND OPTARG opt
    local instance_id status

    while getopts i:s: opt; do
        case $opt in
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
        aws rds modify-db-instance \
            --db-instance-identifier "${instance_id:?}" \
            --publicly-accessible > /dev/null
    elif [[ $status == off ]]; then
        aws rds modify-db-instance \
            --db-instance-identifier "${instance_id:?}" \
            --no-publicly-accessible > /dev/null
    elif [[ -n $instance_id ]]; then
        aws rds describe-db-instances \
            --db-instance-identifier "${instance_id:?}" \
            --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,PubliclyAccessible:PubliclyAccessible}' \
            --output text
    else
        aws rds describe-db-instances \
            --query 'DBInstances[*].{DBInstanceIdentifier:DBInstanceIdentifier,PubliclyAccessible:PubliclyAccessible}' \
            --output text
    fi
}
