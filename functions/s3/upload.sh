#? Description:
#?   Upload file to S3 bucket.
#?
#? Usage:
#?   @upload [-r REGION] [-b BUCKET] [-k KEY] [-o SCHEME] FILE
#?
#? Options:
#?   [-r REGION]   Region name.
#?                 Create bucket in this region if the buctet doesn't exist.
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   [-b BUCKET]   S3 bucket name.
#?                 Valid characters are lowercase letters.
#?                 If omit this, a bucket will be created as name syntax:
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

    local -a region_opt
    local bucket key scheme=s3

    while getopts r:b:k:o: opt; do
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
    xsh aws/s3/bucket/create "${region_opt[@]}" "$bucket" >/dev/null

    # upload file to S3 bucket
    aws s3 cp --only-show-errors "$template" "s3://$bucket/$key"
    if [[ $? -ne 0 ]]; then
        return 255
    fi

    # generate the uploaded S3 object URI
    xsh aws/s3/uri/generate "${region_opt[@]}" -s "$scheme" -b "$bucket" -k "$key"
}
