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
    local OPTIND OPTARG opt

    local scheme

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
    local uri=${1:?}

    if [[ ${scheme:?} == $(xsh /uri/parser -s "$uri" | xsh /string/pipe/lower) ]]; then
        echo "$uri"
        return
    fi

    local bucket=$(xsh aws/s3/uri/parser -b "$uri")
    local key=$(xsh aws/s3/uri/parser -k "$uri")
    local region=$(xsh aws/s3/uri/parser -r "$uri")

    xsh aws/s3/uri/generate -s "$scheme" -b "$bucket" -r "$region" -k "$key"
}
