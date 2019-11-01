#? Description:
#?   Generate S3 object URI.
#?
#? Usage:
#?   @generate [-s SCHEME] [-r REGION] [-b BUCKET] [-k KEY]
#?
#? Options:
#?   [-s SCHEME]   Specify scheme.
#?                 Valid schemes: https, http and s3.
#?                 Default is https.
#?
#?   [-r REGION]   Specify region name.
#?                 This option is meaningful only with scheme `-s http[s]`.
#?                 If omitted this, region will be resolved in following steps:
#?                   1. Try to get the region that the bucket belongs to.
#?                      If the bucket is unset, then skip this step.
#?                   2. Try to get the region from activated AWS CLI profile.
#?                   3. Returns error.
#?
#?   [-b BUCKET]   Specify bucket name.
#?                 If omit this, the URI is generated without bucket.
#?                 This option is a must if `-s s3` is used.
#?
#?   [-k KEY]      Specify object key name.
#?                 If omit this, the URI is generated without key.
#?
#? Output:
#?   * http[s]://[BUCKET.]s3-REGION.amazonaws.com/[/KEY]
#?   * http[s]://[BUCKET.]s3.REGION.amazonaws.com.cn[/KEY]
#?   * s3://BUCKET[/<KEY>]
#?
function generate () {
    local OPTIND OPTARG opt

    # set default
    local scheme=https \
          region bucket key

    while getopts s:r:b:k: opt; do
        case $opt in
            s)
                scheme=$OPTARG
                ;;
            r)
                region=$OPTARG
                ;;
            b)
                bucket=$OPTARG
                ;;
            k)
                key=$OPTARG
                ;;
        esac
    done

    local uri

    case $scheme in
        s3)
            if [[ -z $bucket ]]; then
                xsh log error "bucket: parameter null or not set."
                return 255
            fi
            uri=$scheme://$bucket
            ;;
        https|http)
            if aws --version >/dev/null 2>&1; then
                if [[ -z $region ]]; then
                    # get region that bucket belongs to
                    region=$(aws --query LocationConstraint --output text \
                                 s3api get-bucket-location \
                                 --bucket "$bucket" 2>/dev/null)
                fi

                if [[ -z $region ]]; then
                    # get region according to profile
                    region=$(aws configure get default.region)
                fi
            fi

            if [[ -z $region ]]; then
                xsh log error "region: parameter null or not set."
                return 255
            fi

            # set default
            local delimiter='-'
            local domain_suffix=''

            # special logic for special region CN-*
            if [[ ${region%%-*} == 'cn' ]]; then
                delimiter='.'
                domain_suffix='.cn'
            fi

            uri=s3${delimiter}${region}.amazonaws.com${domain_suffix}

            if [[ -n $bucket ]]; then
                uri=$bucket.$uri
            fi

            uri=${scheme}://$uri
            ;;
        *)
            return 255
            ;;
    esac

    if [[ -n $key ]]; then
        uri=$uri/$key
    fi

    echo "$uri"
}
