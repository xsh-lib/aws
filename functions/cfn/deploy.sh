#? Description:
#?   Deploy AWS CloudFormation stack from template.
#?   The nested templates can be deployed at once.
#?
#? Usage:
#?   @deploy
#?     -t TEMPLATE
#?     [-c CONFIG]
#?     [-p POLICY | -P POLICY_DURING_UPDATE]
#?     [-C DIR]
#?     [-d]
#?     [-s]
#?     [-n STACK_NAME]
#?     [<-o KEY=VALUE> ...]
#?
#? Options:
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
#?   [-d]
#?
#?   Directly updates a stack.
#?   This is a DANGER option, which may cause unexpected recreation/replacement
#?   of AWS resources. More safe way: use -s to create change set first, then
#?   execute the change set after the careful review.
#?
#?   [-s]
#?
#?   Create change set for updating a stack.
#?   The execution of change set needs addtional manual step to trigger.
#?
#?   [-n STACK_NAME]
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
function deploy () {

    #? STACK_NAME[-ENVIRONMENT[-RANDOM]]
    function __get_stack_name__ () {

        function __suffix_stack_name__ () {
            local name=${1:?}

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
        unset -f __suffix_stack_name__
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
        local bucket=${1:?}
        local key=${2:?}
        local template=${3:?}

        local uri

        case $(xsh /uri/parser -s "$template" | xsh /string/lower) in
            http|https)
                # no need to upload
                xsh aws/cfn/tmpl/validate "$template"
                uri=$template
                ;;
            s3)
                # no need to upload
                xsh aws/cfn/tmpl/validate "$template"
                uri=$(xsh aws/s3/uri/translate -s https "$template")
                ;;
            '')
                uri=$(xsh aws/cfn/tmpl/upload -v -b "$bucket" -k "$key" "$template")
                ;;
            *)
                return 255
                ;;
        esac

        printf "%s" "$uri"
    }

    function __deploy__ () {

        # return on error
        xsh /trap/err -e

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
        local name
        for name in "${XSH_AWS_CFN__CFG_PROPERTY_NAMES[@]}"; do
            local $name
        done

        # config
        if [[ -n $config ]]; then
            xsh log info "applying config file options: $config..."
            source "$config"

            xsh aws/cfn/cfg/echo
        fi

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

        # template
        local prekey=$(date +%Y%m%d-%H%M%S)

        xsh log info "uploading template: $template"
        local uri
        uri=$(__upload_template__ "$(__get_bucket_name__ "$stack_name")" "${prekey:?}/$(basename "$template")" "$template")
        if [[ $? -ne 0 ]]; then
            xsh log error "failed to upload template: $template"
            return 255
        fi

        # clean
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

        local item depended_uri key value
        for item in "${DEPENDS[@]}"; do
            key=${item%%=*}
            value=${item#*=}

            # upload depended template
            xsh log info "uploading nested template: $value"
            depended_uri=$(__upload_template__ "$(__get_bucket_name__ "$stack_name")" "${prekey:?}/${key:?}/$(basename "${value:?}")" "${value:?}" "$base_dir")
            if [[ $? -ne 0 ]]; then
                xsh log error "failed to upload template: $template"
                return 255
            fi

            if [[ $DELETE -eq 1 ]]; then
                if [[ $XSH_S3_BUCKET_CREATED -eq 1 ]]; then
                    x-trap-return -F $FUNCNAME -a "xsh aws/s3/bucket/delete \"${bucket:?}\""
                else
                    x-trap-return -F $FUNCNAME -a "aws s3 rm \"$(xsh aws/s3/uri/translate -s s3 "$uri")\""
                fi
            fi

            OPTIONS+=( "${key:?}=${depended_uri:?}" )
        done

        # build downstream command options
        for item in "${OPTIONS[@]}"; do
            pass_options+=( -o "$item" )
        done

        local ret

        # create/update stack
        case $update in
            changeset)
                xsh log info "updating stack by change set: $stack_name"
                xsh aws/cfn/stack/update -s -t "$template" "${pass_options[@]}" "$stack_name"
                ;;
            direct)
                xsh log info "updating stack directly: $stack_name"
                if xsh /io/confirm \
                       -m "Direct update may cause unexpected reources recreation/replacement. Are You Sure?" \
                       -t 30; then
                    xsh aws/cfn/stack/update -d -t "$template" "${pass_options[@]}" "$stack_name"
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

                xsh aws/cfn/stack/create -n "$stack_name" "${pass_options[@]}" "$template"
                ;;
        esac
        ret=$?

        # clean
        if [[ $DELETE -eq 1 ]]; then
            x-trap-return -F $FUNCNAME -a \
                          "xsh aws/cfn/stack/delete \"$stack_name\""
        fi

        if [[ $ret -eq 0 ]]; then
            xsh log info "succeeded."
        else
            xsh log error "failed."
            xsh aws/cfn/stack/event -b "$stack_name"
            if [[ -n $LOGICAL_ID ]]; then
                xsh aws/cfn/stack/log -w "$stack_name" "$LOGICAL_ID"
            fi
        fi

        return $ret
    }


    xsh import /trap/return

    # clean env on return
    x-trap-return -F $FUNCNAME -a "unset -f __get_stack_name__ __get_bucket_name__ \
                               __upload_template__ __deploy__"

    # main
    local OPTIND OPTARG opt

    local template config dir update stack_name
    declare -a options pass_options

    while getopts t:c:p:P:C:dsn:o: opt; do
        case $opt in
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
            d)
                update='direct'
                ;;
            s)
                update='changeset'
                ;;
            n)
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

    (
        if [[ -n $dir ]]; then
            cd "$dir" && __deploy__
        else
            __deploy__
        fi
    )
}
