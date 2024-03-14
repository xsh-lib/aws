#? Description:
#?   Get console log of EC2 instances.
#?
#? Usage:
#?   @log [-r REGION] [-w] -i INSTANCE_ID [...]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-w]
#?
#?   Wait the instance come to running status.
#?   It will poll every 15 seconds until a successful state has been reached. 
#?   Max waiting time is 10 minutes.
#?
#?   -i INSTANCE_ID [...]
#?
#?   EC2 instance identifier.
#?
function log () {
    declare OPTIND OPTARG opt
    declare -a region_opt instance_ids
    declare wait

    while getopts r:wi: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            w)
                wait=1
                ;;
            i)
                instance_ids+=("$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    declare inst_id

    for inst_id in "${instance_ids[@]}"; do
        printf "instance: %s\n" "$inst_id"
        if [[ $wait -eq 1 ]]; then
            printf "waiting the instance come to running..."
            if aws "${region_opt[@]}" ec2 wait instance-running --instance-ids "$inst_id"; then
                printf " [running]\n"
            else
                printf " [timed out]\n"
                continue
            fi
        fi

        declare log
        log=$(aws "${region_opt[@]}" --query Output --output text \
                  ec2 get-console-output --instance-id "$inst_id")
        echo -e "$log"
    done
}
