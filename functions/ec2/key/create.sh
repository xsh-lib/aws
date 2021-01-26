#? Description:
#?   Create EC2 key pair.
#?
#? Usage:
#?   @create [-r REGION] [-f FILE] [-m MODE] NAME
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-f FILE]
#?
#?   Save the private key to the FILE.
#?   If a file with the same name already exists, returns an error.
#?
#?   [-m MODE]
#?
#?   umask mode for the FILE.
#?   Default umask mode is '077', the corresponding *file* permission is '600'.
#?
#?   NAME
#?
#?   Name for the key pair.
#?
#? Output:
#?   The private key created.
#?
function create () {
    declare OPTIND OPTARG opt
    declare -a region_opt
    declare file mode=077

    while getopts r:f:m: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            f)
                file=$OPTARG
                ;;
            m)
                mode=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))

    declare key
    key=$(aws "${region_opt[@]}" --query "KeyMaterial" --output text \
              ec2 create-key-pair --key-name "${1:?}")
    printf "%s\n" "$key"

    if [[ -n $file ]]; then
        if [[ -e $file ]]; then
            xsh log error "file already exists: $file"
            return 255
        fi

        (
            if [[ -n $mode ]]; then
                umask "$mode" || exit
            fi
            printf -- "$key" > "$file"
        )
    fi
}
