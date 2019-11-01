#? Description:
#?   Check EC2 key pair existence.
#?
#? Usage:
#?   @exist [-r REGION] NAME
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   NAME
#?
#?   Name for the key pair.
#?
#? Return:
#?   0: Exists
#?   !=0: Doesn't exist
#?
function exist () {
    local OPTIND OPTARG opt
    local -a region_opt

    while getopts r: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))

    aws "${region_opt[@]}" ec2 describe-key-pairs --key-names "${1:?}" >/dev/null 2>&1
}
