#!/bin/bash -e

#? Description:
#?   Change master user password for RDS.
#?
#? Usage:
#?   @password <INSTANCE_ID> <PASSWORD>
#?
#? Options:
#?   <INSTANCE_ID>   RDS instance identifier. 
#?   <PASSWORD>      New password.
#?
function password () {
    aws rds modify-db-instance \
        --db-instance-identifier "${1:?}" \
        --master-user-password "${2:?}"
}

password "$@"

exit
