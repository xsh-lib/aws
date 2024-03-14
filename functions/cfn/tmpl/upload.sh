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
#?   [-v]          Validate the template before the upload.
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

    if [[ $validate -eq 1 ]]; then
        # validate template
        xsh aws/cfn/tmpl/validate -t "$template"
    fi

    xsh aws/s3/upload "${region_opt[@]}" -b "$bucket" -k "$key" -o https "$template"
}
