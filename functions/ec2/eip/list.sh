#? Description:
#?   List EC2 Elastic IPs.
#?
#? Usage:
#?   @list [-a | -u]
#?
#? Options:
#?   [-a]   List associated EIPs only.
#?   [-u]   List unassociated EIPs only.
#?
function list () {
    local OPTIND OPTARG opt

    local associated

    while getopts au opt; do
        case $opt in
            a)
                associated=1
                ;;
            u)
                associated=0
                ;;
            *)
                return 255
                ;;
        esac
    done

    case $associated in
        1)
            # associated EIPs only
            aws ec2 describe-addresses \
                --query "Addresses[?InstanceId==*].PublicIp"
            ;;
        0)
            # unassociated EIPs only
            aws ec2 describe-addresses \
                --query "Addresses[?InstanceId==null].PublicIp"
            ;;
        '')
            # all EIPs
            aws ec2 describe-addresses \
                --query "Addresses[*].PublicIp"
            ;;
        *)
            return 255
            ;;
    esac
}
