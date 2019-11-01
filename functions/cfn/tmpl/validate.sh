#? Description:
#?   Validate CloudFormation template file.
#?
#? Usage:
#?   @validate -t TEMPALTE
#?
#? Options:
#?   -t TEMPLATE   Template file.
#?                 The TEMPLATE must be either of:
#?                   * Local file path or stdin.
#?                   * S3 object URI in scheme `s3`, `http` or `https`.
#?
#? Examples:
#?   $ @validate -t /tmp/template.json
#?
#?   $ cat /tmp/template.json | @validate -t
#?
#?   $ @validate -t s3://mybucket/template.json
#?
#?   $ @validate -t https://mybucket.s3-ap-northeast-1.awsamazon.com/template.json
#?
function validate () {
    local OPTIND OPTARG opt

    local template
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

    local scheme
    scheme=$(xsh /uri/parser -s "$template" | xsh /string/pipe/lower)

    case $scheme in
        s3)
            template=$(xsh aws/s3/uri/translate -s https "$template")
            aws cloudformation validate-template --template-url "$template" >/dev/null
            ;;
        http|https)
            aws cloudformation validate-template --template-url "$template" >/dev/null
            ;;
        '')
            aws cloudformation validate-template --template-body "$(cat "$template")" >/dev/null
            ;;
        *)
            return 255
            ;;
    esac
}
