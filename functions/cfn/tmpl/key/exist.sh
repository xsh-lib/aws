#? Description:
#?   Check the existence of EC2 key pairs which are referred by the template.
#?   The template should be a well formatted JSON file and has at least a key in name
#?   `Resources`.
#?   The checkable key pairs should have the key name as `KeyName` and have the value
#?   in string.
#?
#? Usage:
#?   @exist -t TEMPLATE
#?
#? Options:
#?   -t TEMPLATE   Template file.
#?                 The TEMPLATE must be either of:
#?                   * Local file path or stdin.
#?
#? Example:
#?   $ @exist -t /dev/stdin <<< '{"Resources": {"myinstance": {"Properties": {"KeyName": "foo"}}}}'
#?   Checking key pair existence: foo... [Not Found]
#?
function exist () {
    declare OPTIND OPTARG opt

    declare template
    while getopts t: opt; do
        case $opt in
            t)
                template=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $template ]]; then
        xsh log error "template: parameter null or not set."
        return 255
    fi

    declare names
    names=(
        $(xsh /json/parser eval "$(cat "$template")" \
              '[val["Properties"]["KeyName"] for val in {JSON}["Resources"].values() \
                   if val.has_key("Properties") \
                   and val["Properties"].has_key("KeyName") \
                   and isinstance(val["Properties"]["KeyName"], (str, unicode))]' \
              | tr -d '[]" ' \
              | sed 's/,/ /g') )
    
    declare ret=0 name

    if [[ ${#names[@]} -eq 0 ]]; then
        printf "no checkable key pairs found.\n"
        return
    fi

    for name in "${names[@]}"; do
        printf "checking key pair existence: %s..." "$name"
        if xsh aws/ec2/key/exist "$name"; then
            printf " [OK]\n"
        else
            printf " [Not Found]\n"
            ret=$((ret + 1))
        fi
    done

    return $ret
}
