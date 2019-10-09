#? Description:
#?   Upload CloudFormation template to S3 bucket.
#?
#? Usage:
#?   @upload [-b BUCKET] [-k KEY] [-v] TEMPLATE
#?
#? Options:
#?   [-b BUCKET]   S3 bucket name.
#?                 Valid characters are lowercase letter,.
#?                 If omit this, a default bucket name is generated in syntax:
#?                 `aws-cfn-tmpl-upload-$RANDOM`.
#?
#?   [-k KEY]      S3 bucket object key.
#?                 If omit this, a default key is generated with the basename of TEMPLATE.
#?
#?   [-v]          Validate the template before the upload.
#?
#?   TEMPLATE      Template to upload.
#?                 The TEMPLATE must be either of:
#?                   * Local file path.
#?                   * S3 object URI in scheme `s3`.
#?
#? Output:
#?   The URI of the uploaded S3 object, in scheme `https`.
#?
function upload () {
    local OPTIND OPTARG opt

    local bucket key validate

    while getopts b:k:v opt; do
        case $opt in
            b)
                bucket=$OPTARG
                ;;
            k)
                key=$OPTARG
                ;;
            v)
                validate=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    local template=${1:?}

    if [[ -z $bucket ]]; then
        bucket=aws-cfn-tmpl-upload-$RANDOM
    fi

    if [[ $validate -eq 1 ]]; then
        # validate template
        xsh aws/cfn/tmpl/validate "$template"
        if [[ $? -ne 0 ]]; then
            return 255
        fi
    fi

    xsh aws/s3/upload -b "$bucket" -k "$key" -o https "$template"
}
