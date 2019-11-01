#? Description:
#?   Create a S3 bucket.
#?   The creation is region sensed.
#?
#? Usage:
#?   @create [-r REGION] NAME
#?
#? Options:
#?   [-r REGION]   Region name.
#?                 Create bucket in this region.
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   NAME          Bucket name.
#?
#? Variables:
#?   * XSH_S3_BUCKET_CREATED
#?
#?     1: Creaed
#?     0: Not created
#?
function create () {
    declare OPTIND OPTARG opt

    declare -a region_opt
    while getopts r: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    declare name=${1:?}

    XSH_S3_BUCKET_CREATED=0

    if xsh aws/s3/bucket/exist "$name"; then
        xsh log warning "$name: the bucket already exists."
    else
        if aws "${region_opt[@]}" s3 mb "s3://$name"; then
            XSH_S3_BUCKET_CREATED=1
        else
            return $?
        fi
    fi
}
