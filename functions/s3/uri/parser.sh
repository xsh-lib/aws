#? Description:
#?   Parse S3 object URI and return whether the URI is valid.
#?
#?   URI = scheme://authority[path]
#?   scheme = <s3|http|https>
#?   authority = host
#?   host = bucket[.s3<-|.>region.amazonaws.com[.cn]]
#?   path = /key
#?
#? Usage:
#?   @parser [OPTIONS] URI
#?
#? Options:
#?   -s    Output Scheme.
#?   -a    Output Authority.
#?   -h    Output Host.
#?   -p    Output Path.
#?   -r    Output Region.
#?   -b    Output Bucket.
#?   -k    Output Key.
#?   URI   The S3 object URI.
#?
#? Output:
#?   The specified part of the S3 object URI.
#?
#? Return:
#?   0: Valid
#?   != 0: Invalid
#?
#? Example:
#?   $ @parser -b https://mybucket.s3-ap-northeast-1.amazonaws.com/foo/bar.zip
#?   mybucket
#?
#? URI Samples:
#?
#?      bucket,host   key
#?        ┌──┴───┐ ┌────┴────┐
#?   s3://mybucket/foo/bar.zip
#?   └|   └───┬──┘└────┬─────┘
#?  scheme authority  path
#?
#?            bucket         region                        key
#?           ┌──┴───┐    ┌─────┴──────┐                ┌────┴────┐
#?   https://mybucket.s3-ap-northeast-1.amazsonaws.com/foo/bar.zip
#?   └─┬─┘   └───────────────────┬───────────────────┘└────┬─────┘
#?   scheme                authority,host                 path
#?
#? Bugs:
#?
#?   1.The URI with bucket in path is unsupported by now.
#?
#?                    region                    bucket      key
#?                ┌─────┴──────┐               ┌──┴───┐ ┌────┴────┐
#?     https://s3-ap-northeast-1.amazonaws.com/mybucket/foo/bar.zip
#?     └─┬─┘   └──────────────┬──────────────┘└─────────┬─────────┘
#?     scheme           authority,host                 path
#?
#? Link:
#?   * https://en.wikipedia.org/wiki/Uniform_Resource_Identifier
#?
function parser () {
    # get the last parameter
    declare uri=${!#}

    #? mybucket.s3-ap-northeast-1.amazsonaws.com
    #? mybucket.s3.cn-north-1.amazsonaws.com.cn
    declare REGEX_HOST='^([a-z0-9.-]+)(\.([^-./]+[-.]([a-zA-Z]+-[a-zA-Z-]+-[0-9])))(\.[^/]+)'
    #?                 ↑            ↑  ↑           ↑                             ↑
    #?                 1 bucket     |  |           4 region                      5 .amazonaws.com[.cn]
    #?                              |  3 s3<-|.>region
    #?                              2 .s3<-|.>region

    declare OPTIND OPTARG opt

    while getopts sahprbk opt; do
        case $opt in
            s|a|h|p)
                xsh /uri/parser -$opt "$uri"
                ;;
            r|b)
                declare scheme host
                scheme=$(xsh /uri/parser -s "$uri" | xsh /string/pipe/lower)
                host=$(xsh /uri/parser -h "$uri")

                case $scheme in
                    s3)
                        case $opt in
                            r)
                                :
                                ;;
                            b)
                                echo "$host"
                                ;;
                        esac
                        ;;
                    *)
                        if [[ ! $host =~ $REGEX_HOST ]]; then
                            xsh log error "$uri: URI is not valid."
                            return 255
                        fi

                        case $opt in
                            r)
                                echo "${BASH_REMATCH[4]}"
                                ;;
                            b)
                                echo "${BASH_REMATCH[1]}"
                                ;;
                        esac
                        ;;
                esac
                ;;
            k)
                xsh /uri/parser -r "$uri"
                ;;
            *)
                return 255
                ;;
        esac
    done
}
