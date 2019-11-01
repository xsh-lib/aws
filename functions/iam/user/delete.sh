#? Description:
#?   Delete an IAM user.
#?
#? Usage:
#?   @delete [-f] USERNAME
#?
#? Options:
#?   [-f]   Force to delete all attached user policies and access key.
#?
function delete () {
    declare OPTIND OPTARG opt

    declare force
    while getopts f opt; do
        case $opt in
            f)
                force=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ $force -eq 1 ]]; then
        xsh aws/iam/user/policy/delete -u "${1:?}"
        xsh aws/iam/user/key/delete -u "${1:?}"
    fi

    xsh log info "$1: deleting IAM user."
    aws iam delete-user --user-name "${1:?}"
}
