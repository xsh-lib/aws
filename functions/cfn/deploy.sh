#? Description:
#?   Deploy AWS CloudFormation stack from template.
#?   The nested templates can be deployed at once.
#?
#? Usage:
#?   @deploy
#?     [-r REGION]
#?     -t TEMPLATE
#?     [-c CONFIG]
#?     [-p POLICY | -P POLICY_DURING_UPDATE]
#?     [-C DIR]
#?     [-D]
#?     [-S]
#?     [-s STACK_NAME]
#?     [<-o KEY=VALUE> ...]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -t TEMPLATE
#?
#?   Template file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?
#?   [-c CONFIG]
#?
#?   Config file.
#?   The configs inside this file can be overridden by `-o` options.
#?
#?   [-p POLICY]
#?
#?   Stack policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This parameter is ignored with -s (create change set).
#?
#?   [-P POLICY_DURING_UPDATE]
#?
#?   Stack update policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This parameter can be only used with -d (directly update stack).
#?   And it is ignored with -s (create change set).
#?
#?   [-C DIR]
#?
#?   Change to the DIR.
#?
#?   [-D]
#?
#?   Directly updates a stack.
#?   This is a DANGER option, which may cause unexpected recreation/replacement
#?   of AWS resources. More safe way: use -s to create change set first, then
#?   execute the change set after the careful review.
#?
#?   [-S]
#?
#?   Create change set for updating a stack.
#?   The execution of change set needs addtional manual step to trigger.
#?
#?   [-s STACK_NAME]
#?
#?   The name for the stack.
#?   The name must be unique in the region in which you are creating the stack.
#?   If supplied -d or -s, and using RANDOM_STACK_NAME_SUFFIX=1, then must supply
#?   this option, otherwise the updating stack won't be found.
#?   If set this, STACK_NAME in config file will be ignored.
#?
#?   [<-o KEY=VALUE> ...]
#?
#?   The configs here take precedence over the config file.
#?
#? Example:
#?   $ xsh aws/cfn/deploy -C /tmp/aws-cfn-vpn -t stack.json -c sandbox.conf
#?   $ xsh aws/cfn/deploy -C /tmp/aws-cfn-vpn -t stack.json -c sandbox.conf -o DELETE=0 -o OPTIONS=KeyPairName=mykey
#?
#? @xsh import /trap/return
#? @xsh /trap/err -eE
#? @subshell
#?
function deploy () {

    #? STACK_NAME[-ENVIRONMENT[-RANDOM]]
    function __get_stack_name__ () {

        function __suffix_stack_name__ () {
            declare name=${1:?}

            if [[ -n $ENVIRONMENT ]]; then
                name=$name-$ENVIRONMENT
            fi

            if [[ -n $RANDOM_STACK_NAME_SUFFIX ]]; then
                name=$name-$RANDOM
            fi

            printf "%s" "$name"
        }

        if [[ -z $STACK_NAME ]]; then
            #xsh log error "parameter STACK_NAME null or not set."
            return 255
        fi

        __suffix_stack_name__ "$STACK_NAME"
    }

    function __get_bucket_name__ () {
        if [[ -n $ENVIRONMENT ]]; then
            xsh /string/lower "${STACK_NAME:?}-${ENVIRONMENT}-cfn-templates"
        else
            xsh /string/lower "${STACK_NAME:?}-cfn-templates"
        fi
    }

    #? upload the template to the bucket with a default key
    function __upload_template__ () {
        declare bucket=${1:?}
        declare key=${2:?}
        declare template=${3:?}
        declare -a region_opt
        if [[ -n $4 ]]; then
            region_opt=(-r "$4")
        fi

        declare uri

        case $(xsh /uri/parser -s "$template" | xsh /string/lower) in
            http|https)
                # no need to upload
                xsh aws/cfn/tmpl/validate -t "$template"
                uri=$template
                ;;
            s3)
                # no need to upload
                xsh aws/cfn/tmpl/validate -t "$template"
                uri=$(xsh aws/s3/uri/translate -s https "$template")
                ;;
            '')
                # -v: do the validation
                uri=$(xsh aws/cfn/tmpl/upload "${region_opt[@]}" -v -b "$bucket" -k "$key" -t "$template")
                ;;
            *)
                return 255
                ;;
        esac

        printf "%s" "$uri"
    }


    # main
    declare OPTIND OPTARG opt

    declare region template config dir update stack_name
    declare -a region_opt options pass_options

    while getopts r:t:c:p:P:C:DSs:o: opt; do
        case $opt in
            r)
                region=${OPTARG:?}
                region_opt=(-r "${OPTARG:?}")
                ;;
            t)
                template=${OPTARG:?}
                ;;
            c)
                config=${OPTARG:?}
                ;;
            p|P)
                pass_options+=( -$opt "${OPTARG:?}" )
                ;;
            C)
                dir=${OPTARG:?}
                ;;
            D)
                update='direct'
                ;;
            S)
                update='changeset'
                ;;
            s)
                stack_name=${OPTARG:?}
                ;;
            o)
                options+=( "${OPTARG:?}" )
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $template ]]; then
        xsh log error "parameter TEMPLATE null or not set."
        return 255
    fi

    # change work dir
    if [[ -n $dir ]]; then
        cd "$dir"
    fi

    # initialize local variables:
    #   ENVIRONMENT
    #   STACK_NAME
    #   RANDOM_STACK_NAME_SUFFIX
    #   DEPENDS
    #   LOGICAL_ID
    #   TIMEOUT
    #   OPTIONS
    #   DISABLE_ROLLBACK
    #   DELETE
    declare name
    for name in "${XSH_AWS_CFN__CFG_PROPERTY_NAMES[@]}"; do
        declare $name
    done

    # config
    if [[ -n $config ]]; then
        xsh log info "applying config file options: $config..."
        source "$config"

        xsh aws/cfn/cfg/echo
    fi

    # override config
    if [[ -n ${options[@]} ]]; then
        xsh log info "applying command line options..."
        xsh /env/override -a -m -s = "${options[@]}"

        xsh aws/cfn/cfg/echo
    fi

    # stack name
    if [[ -z $stack_name ]]; then
        stack_name=$(__get_stack_name__)
    fi
    OPTIONS+=( "NS=$stack_name" )
    OPTIONS+=( "NSLowerCase=$(xsh /string/lower "$stack_name")" )

    # bucket name
    declare bucket_name
    bucket_name=$(__get_bucket_name__ "$stack_name")

    # the prefix of s3 object key for template
    declare prekey
    prekey=$(date +%Y%m%d-%H%M%S)

    # upload template
    xsh log info "uploading template: $template"
    declare uri
    uri=$(__upload_template__ \
              "$bucket_name" \
              "${prekey:?}/$(basename "$template")" \
              "$template" \
              "$region")

    # trap clean commands
    if [[ $DELETE -eq 1 ]]; then
        x-trap-return -F $FUNCNAME \
                      "xsh log info \"cleaning environment of $FUNCNAME.\""

        x-trap-return -F $FUNCNAME -a \
                      "if xsh /io/confirm -t 60 -m \"skip to delete stack and template?\"; then
                          xsh log info \"skipped clean\".
                          return
                       fi"

        if [[ $XSH_S3_BUCKET_CREATED -eq 1 ]]; then
            x-trap-return -F $FUNCNAME -a "xsh aws/s3/bucket/delete \"${bucket:?}\""
        else
            x-trap-return -F $FUNCNAME -a "aws s3 rm \"$(xsh aws/s3/uri/translate -s s3 "$uri")\""
        fi
    fi

    # bucket name
    bucket_name=$(__get_bucket_name__ "$stack_name")

    declare item depended_uri key value
    for item in "${DEPENDS[@]}"; do
        key=${item%%=*}
        value=${item#*=}

        # upload depended template
        xsh log info "uploading nested template: $value"
        depended_uri=$(__upload_template__ \
                           "$bucket_name" \
                           "${prekey:?}/${key:?}/$(basename "${value:?}")" \
                           "${value:?}" \
                           "$region")

        # trap clean commands
        if [[ $DELETE -eq 1 ]]; then
            if [[ $XSH_S3_BUCKET_CREATED -eq 1 ]]; then
                x-trap-return -F $FUNCNAME -a "xsh aws/s3/bucket/delete \"${bucket:?}\""
            else
                x-trap-return -F $FUNCNAME -a "aws s3 rm \"$(xsh aws/s3/uri/translate -s s3 "$depended_uri")\""
            fi
        fi

        OPTIONS+=( "${key:?}=${depended_uri:?}" )
    done

    for item in "${LAMBDA[@]}"; do
        key=${item%%=*}
        value=${item#*=}

        param_name_s3bucket=${key%%:*}
        param_name_s3key=${key#*:}

        declare zipfile
        # zip local lambda if not zipped
        if file "$value" | grep -q 'Zip archive data'; then
            zipfile=$value
        else
            zipfile=${value}.zip
            zip "$zipfile" "$value"
        fi

        declare s3key=${prekey:?}/$(basename "$zipfile")
        # upload depended lambda
        xsh log info "uploading depended lambda: $zipfile"
        xsh aws/s3/upload "${region_opt[@]}" -b "$bucket_name" -k "$s3key" "$zipfile"

        OPTIONS+=( "${param_name_s3bucket:?}=${bucket_name:?}" )
        OPTIONS+=( "${param_name_s3key:?}=${s3key:?}" )
    done

    # build downstream command options
    for item in "${OPTIONS[@]}"; do
        pass_options+=( -o "$item" )
    done

    declare ret

    # create/update stack
    case $update in
        changeset)
            xsh log info "updating stack by change set: $stack_name"
            xsh aws/cfn/stack/update "${region_opt[@]}" -s "$stack_name" -S -t "$template" "${pass_options[@]}" \
                || ret=$?
            ;;
        direct)
            xsh log info "updating stack directly: $stack_name"
            if xsh /io/confirm \
                   -m "Direct update may cause unexpected reources recreation/replacement. Are You Sure?" \
                   -t 30; then
                xsh aws/cfn/stack/update "${region_opt[@]}" -s "$stack_name" -D -t "$template" "${pass_options[@]}" \
                    || ret=$?
            else
                ret=1
            fi
            ;;
        *)
            xsh log info "creating with stack name: $stack_name"

            if [[ -n $TIMEOUT ]]; then
                pass_options+=( -w "$TIMEOUT" )
            fi

            if [[ $DISABLE_ROLLBACK -eq 1 ]]; then
                pass_options+=( -R )
            fi

            xsh aws/cfn/stack/create "${region_opt[@]}" -s "$stack_name" -t "$template" "${pass_options[@]}" \
                || ret=$?
            ;;
    esac

    # trap clean commands
    if [[ $DELETE -eq 1 ]]; then
        x-trap-return -F $FUNCNAME -a \
                      "xsh aws/cfn/stack/delete ${region_opt[@]} -s \"$stack_name\""
    fi

    if [[ $ret -eq 0 ]]; then
        xsh log info "succeeded."
    else
        xsh log error "failed."
        xsh aws/cfn/stack/event "${region_opt[@]}" -e -s "$stack_name"
        if [[ -n $LOGICAL_ID ]]; then
            xsh aws/cfn/stack/log "${region_opt[@]}" -w -s "$stack_name" -l "$LOGICAL_ID"
        fi
    fi

    return $ret
}
