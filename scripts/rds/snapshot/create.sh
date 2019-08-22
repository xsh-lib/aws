#!/bin/bash -e

#? Description:
#?   Create snapshots for RDS instances.
#?
#? Usage:
#?   @create -i <INSTANCE_ID> [...]
#?
#? Options:
#?   -i <INSTANCE_ID> [...]
#?
#?   RDS instance identifier.
#?
function create () {
    local OPTIND OPTARG opt

    declare -a instance_ids
    while getopts i: opt; do
        case $opt in
            i)
                instance_ids[${#instance_ids[@]}]=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    local instance_id ts
    for instance_id in "${instance_ids[@]}"; do
        ts=$(date '+%Y%m%d-%H%M')

        # Creating snapshot
        aws rds create-db-snapshot \
            --db-instance-identifier "${instance_id:?}" \
            --db-snapshot-identifier "${instance_id:?}-${ts:?}"
    done
}

create "$@"

exit
