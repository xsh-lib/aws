#? Description:
#?   Get console log of EC2 instances.
#?
#? Usage:
#?   @log [-w] <INSTANCE_ID> [...]
#?
#? Options:
#?   [-w]           Wait the instance being running status.
#?   <INSTANCE_ID>  Instance identifier.
#?
function log () {
    local OPTIND OPTARG opt
    local wait

    while getopts w opt; do
        case $opt in
            w)
                wait=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))

    local inst_id

    for inst_id in "$@"; do
        if [[ $wait -eq 1 ]]; then
            xsh log info "waiting for running status for instance: $inst_id"
            aws ec2 wait instance-running --instance-ids "$inst_id"
        fi
        xsh log info "instance: $inst_id"

        echo -e "$(aws ec2 get-console-output --instance-id "$inst_id")"
    fi
}
