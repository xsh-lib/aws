#? Description:
#?   Change master user password for RDS.
#?
#? Usage:
#?   @password [-r REGION] -i INSTANCE_ID -p PASSWORD
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -i INSTANCE_ID
#?
#?   RDS instance identifier.
#?
#?   -p PASSWORD
#?
#?   New password.
#?
function password () {
    local OPTIND OPTARG opt
    local -a region_opt
    local instance_id password

    while getopts r:i:p: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            i)
                instance_id=$OPTARG
                ;;
            p)
                password=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    aws "${region_opt[@]}" \
        rds modify-db-instance --db-instance-identifier "${instance_id:?}" \
        --master-user-password "${password:?}"
}
