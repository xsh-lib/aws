#? Description:
#?   Upload file to S3 bucket.
#?
#? Usage:
#?   @upload [-b BUCKET] [-k KEY] [-o SCHEME] FILE
#?
#? Options:
#?   [-b BUCKET]   S3 bucket name.
#?                 Valid characters are lowercase letter,.
#?                 If omit this, a default bucket name is generated in syntax:
#?                 `aws-s3-upload-$RANDOM`.
#?
#?   [-k KEY]      S3 bucket object key.
#?                 If omit this, a default key is generated with the basename of FILE.
#?
#?   [-o SCHEME]   Output the uploaded S3 object URI in specified SCHEME.
#?                 Valid schemes: [s3 | https | http]. Default is `s3`.
#?
#?   FILE          File to upload.
#?                 The FILE must be either of:
#?                   * Local file path.
#?                   * S3 object URI in scheme `s3`.
#?
#? Output:
#?   The URI of the uploaded S3 object.
#?
function upload () {
    local OPTIND OPTARG opt

    local bucket key scheme=s3

    while getopts b:k:o: opt; do
        case $opt in
            b)
                bucket=$OPTARG
                ;;
            k)
                key=$OPTARG
                ;;
            o)
                scheme=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    local template=${1:?}

    if [[ -z $bucket ]]; then
        bucket=aws-s3-upload-$RANDOM
    fi

    if [[ -z $key ]]; then
        key=$(basename "$template")
    fi

    # create bucket if not exsit
    xsh aws/s3/bucket/create "$bucket" >/dev/null

    # upload file to S3 bucket
    aws s3 cp --only-show-errors "$template" "s3://$bucket/$key"
    if [[ $? -ne 0 ]]; then
        return 255
    fi

    # generate the uploaded S3 object URI
    xsh aws/s3/uri/generate -s "$scheme" -b "$bucket" -k "$key"
}
