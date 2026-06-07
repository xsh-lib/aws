#? Description:
#?   Upload CloudFormation template to S3 bucket.
#?
#? Usage:
#?   @upload [-r REGION] [-b BUCKET] [-k KEY] [-v] -t TEMPLATE
#?
#? Options:
#?   [-r REGION]   Region name.
#?                 Create bucket in this region if the bucket doesn't exist.
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   [-b BUCKET]   S3 bucket name.
#?                 Valid characters are lowercase letters.
#?                 If omit this, a bucket will be created as name syntax:
#?                 `aws-cfn-tmpl-upload-$RANDOM`.
#?
#?   [-k KEY]      S3 bucket object key.
#?                 If omit this, a default key is generated with the basename of TEMPLATE.
#?
#?   [-v]          Validate the template (after the upload, via the S3 URL, so
#?                 templates larger than the 51200-byte inline limit validate).
#?
#?   -t TEMPLATE   Template to upload.
#?                 The TEMPLATE must be either of:
#?                   * Local file path or stdin.
#?                   * S3 object URI in scheme `s3`.
#?
#? Output:
#?   The URI of the uploaded S3 object, in scheme `https`.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function upload () {
    declare OPTIND OPTARG opt

    declare -a region_opt
    declare bucket=aws-cfn-tmpl-upload-$RANDOM \
          key validate template

    while getopts r:b:k:vt: opt; do
        case $opt in
            r)
                region_opt=(-r "${OPTARG:?}")
                ;;
            b)
                bucket=$OPTARG
                ;;
            k)
                key=$OPTARG
                ;;
            v)
                validate=1
                ;;
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

    # Upload first, then (optionally) validate via the uploaded S3 URL rather than
    # the local file. CloudFormation's inline `--template-body` is capped at 51200
    # bytes, while `--template-url` (S3) accepts templates up to its larger limit.
    # Validating post-upload therefore lets large local templates (>51200 bytes)
    # validate, which inline validation would reject with:
    #   "templateBody ... Member must have length less than or equal to 51200".
    declare uri
    uri=$(xsh aws/s3/upload "${region_opt[@]}" -b "$bucket" -k "$key" -o https "$template")

    if [[ $validate -eq 1 ]]; then
        xsh aws/cfn/tmpl/validate -t "$uri"
    fi

    printf '%s\n' "$uri"
}
