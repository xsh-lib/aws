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

    declare scheme
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
            # CloudFormation's ValidateTemplate API rejects --template-body > 51200 bytes.
            # For large templates, skip inline validation — CFN validates the template again
            # when create-stack / update-stack is called with the S3 TemplateURL.
            if (( $(wc -c < "$template") <= 51200 )); then
                aws cloudformation validate-template --template-body "$(cat "$template")" >/dev/null
            else
                xsh log warn "template '$(basename "$template")': body size $(wc -c < "$template") bytes > 51200 limit; skipping inline validation."
            fi
            ;;
        *)
            return 255
            ;;
    esac
}
