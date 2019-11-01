#? Description:
#?   Translate S3 object URI presentation between schemes.
#?
#? Usage:
#?   @translate <-s SCHEME> URI
#?
#? Options:
#?   <-s SCHEME>   Target scheme translating to.
#?                 Valid schemes: https, http and s3.
#?
#?   URI           S3 object URI to translate.
#?
function translate () {
    declare OPTIND OPTARG opt

    declare scheme

    while getopts s: opt; do
        case $opt in
            s)
                scheme=$(xsh /string/lower "$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND -1))
    declare uri=${1:?}

    if [[ ${scheme:?} == $(xsh /uri/parser -s "$uri" | xsh /string/pipe/lower) ]]; then
        echo "$uri"
        return
    fi

    declare bucket key region
    bucket=$(xsh aws/s3/uri/parser -b "$uri")
    key=$(xsh aws/s3/uri/parser -k "$uri")
    region=$(xsh aws/s3/uri/parser -r "$uri")

    xsh aws/s3/uri/generate -s "$scheme" -b "$bucket" -r "$region" -k "$key"
}
