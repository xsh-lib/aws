#? Description:
#?   Validate CloudFormation template file.
#?
#? Usage:
#?   @validate <TEMPALTE>
#?
#? Options:
#?   <TEMPLATE>   Template file.
#?                Could be a local file path or stdin, or a S3 object URI.
#?
#? Examples:
#?   $ @validate /tmp/template.json
#?
#?   $ cat /tmp/template.json | @validate
#?
#?   $ @validate s3://mybucket/template.json
#?
#?   $ @validate https://mybucket.s3-ap-northeast-1.awsamazon.com/template.json
#?
function validate () {
    local template=$1

    if [[ -z $template && ! -s /dev/stdin ]]; then
        printf "$FUNCNAME: ERROR: parameter TEMPLATE null or not set.\n" >&2
        return 255
    fi

    local scheme

    if [[ -n $template ]]; then
        scheme=$(xsh /uri/parser -s "$template" | xsh /string/pipe/lower)
    fi

    case $scheme in
        s3|http|https)
            template=$(xsh aws/s3/uri/translate -s https "$template")
            aws cloudformation validate-template --template-url "$template" 1>/dev/null
            ;;
        '')
            cat "${template:--}" \
                | aws cloudformation validate-template --template-body "$(cat -)" 1>/dev/null
            ;;
        *)
            return 255
            ;;
    esac
}
