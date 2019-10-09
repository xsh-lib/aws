#? Description:
#?   Create EC2 key pair.
#?
#? Usage:
#?   @create [-f FILE] [-m MODE] <NAME>
#?
#? Options:
#?   [-f FILE]   Save the private key to the FILE.
#?               If a file with the same name already exists, returns an error.
#?   [-m MODE]   umask mode for the FILE.
#?   <NAME>      Name for the key pair.
#?
function create () {
    local OPTIND OPTARG opt
    local file mode

    while getopts f:m: opt; do
        case $opt in
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

    local json=$(aws ec2 create-key-pair --key-name "${1:?}")
    printf "%s\n" "$json"

    local key=$(xsh /json/parser get "$json" "KeyMaterial")

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
