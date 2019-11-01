#? Description:
#?   Remove Metadata node for CloudFormation Desgin form template.
#?
#? Usage:
#?   @remove -t TEMPLATE
#?
#? Options:
#?   -t TEMPLATE   Template file.
#?                 The TEMPLATE must be either of:
#?                   * Local file path or stdin.
#?
#? Output:
#?   The template removed the Metadata node.
#?
#? Example:
#?   $ @remove -t /dev/stdin <<< '{"Metadata": {}, "foo": "bar"}'
#?   {"foo": "bar"}
#?
function remove () {
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

    xsh /json/parser eval "$(cat "$template")" \
        'dict((key, {JSON}[key]) for key in {JSON} if key != "Metadata")'
}
