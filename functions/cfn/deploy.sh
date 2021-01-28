#? Description:
#?   Deploy AWS CloudFormation stack from template.
#?   The nested templates and non-inline Lambda Functions can be deployed at once.
#?
#? Usage:
#?   @deploy -g
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
#?   -g
#?
#?   Generate a blank config file as a start of your own.
#?
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
#?   Config file using to deploy the template.
#?   The syntax of the config is described in the `CONFIG` section.
#?   The configs inside this file can be overridden by `-o` options.
#?
#?   [-p POLICY]
#?
#?   Stack policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This parameter is ignored with -S (create change set).
#?
#?   [-P POLICY_DURING_UPDATE]
#?
#?   Stack update policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This parameter can be only used with -d (directly update stack).
#?   And it is ignored with -S (create change set).
#?
#?   [-C DIR]
#?
#?   Change to the DIR.
#?
#?   [-D]
#?
#?   Directly updates a stack.
#?   This is a DANGER option, which may cause unexpected recreation/replacement
#?   of AWS resources. More safe way: use -S to create change set first, then
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
#?   If supplied -D or -S, and using RANDOM_STACK_NAME_SUFFIX=1, then must supply
#?   this option, otherwise the updating stack won't be found.
#?   If set this, STACK_NAME in config file will be ignored.
#?
#?   [<-o KEY=VALUE> ...]
#?
#?   The configs here take precedence over the config file.
#?
#? CONFIG:
#?   ## Environment variables used by xsh utility `aws/cfn/deploy`.
#?   ## Reference: https://github.com/xsh-lib/aws
#?
#?   # Format version of this config file.
#?   # Used to check the compatibility with xsh utility.
#?   VERSION=0.1.0
#?
#?   ## Below configs can be overridden in command line while calling `aws/cfn/deploy`.
#?
#?   # STACK_NAME=<StackName>
#?   #
#?   # Required: Yes
#?   # Default: None
#?   # Valid Characters: [a-zA-Z0-9-]
#?   # ---
#?   # Example:
#?   #   STACK_NAME=MyStack
#?
#?   STACK_NAME=
#?
#?   # ENVIRONMENT=[Name]
#?   #
#?   # Required: No
#?   # Default: None
#?   # Valid Characters: [a-zA-Z0-9-]
#?   # Description:
#?   #   Environment name, set whatever a name you like or leave it empty.
#?   #   If set this, the full stack name will look like: {STACK_NAME}-{ENVIRONMENT}
#?   # ---
#?   # Example:
#?   #   ENVIRONMENT=DEV
#?
#?   ENVIRONMENT=
#?
#?   # RANDOM_STACK_NAME_SUFFIX=[0 | 1]
#?   #
#?   # Required: No
#?   # Default: None
#?   # Valid Values:
#?   #   1: Suffix stack name as:
#?   #      {STACK_NAME}-{RANDOM_STACK_NAME_SUFFIX}
#?   #      or: {STACK_NAME}-{ENVIRONMENT}-{RANDOM_STACK_NAME_SUFFIX}
#?   #      Usually set this for test purpose.
#?   #   0: No suffix on stack name.
#?   # ---
#?   # Example:
#?   #   RANDOM_STACK_NAME_SUFFIX=1
#?
#?   RANDOM_STACK_NAME_SUFFIX=
#?
#?   # DEPENDS=( <ParameterName>=<NestedTemplate> )
#?   #
#?   # Required: Yes if has nested template, otherwise No
#?   # Default: None
#?   # Syntax:
#?   #   <ParameterName>: The name of template parameter that is referred at the
#?   #                    value of nested template property `TemplateURL`.
#?   #   <NestedTemplate>: A local path or a S3 URL starting with `s3://` or
#?   #                     `https://` pointing to the nested template.
#?   #                     The nested templates at local is going to be uploaded
#?   #                     to S3 Bucket automatically during the deployment.
#?   # Description:
#?   #   Double quote the pairs which contain whitespaces or special characters.
#?   #   Use `#` to comment out.
#?   # ---
#?   # Example:
#?   #   DEPENDS=(
#?   #       NestedTemplateFooURL=/path/to/nested/foo/stack.json
#?   #       NestedTemplateBarURL=/path/to/nested/bar/stack.json
#?   #   )
#?
#?   DEPENDS=()
#?
#?   # LAMBDA=( <S3BucketParameterName>:<S3KeyParameterName>=<LambdaFunction> )
#?   #
#?   # Required: Yes if has None-inline Lambda Function, otherwise No
#?   # Default: None
#?   # Syntax:
#?   #   <S3BucketParameterName>: The name of template parameter that is referred
#?   #                            at the value of Lambda property `Code.S3Bucket`.
#?   #   <S3KeyParameterName>: The name of template parameter that is referred
#?   #                         at the value of Lambda property `Code.S3Key`.
#?   #   <LambdaFunction>: A local path or a S3 URL starting with `s3://` pointing
#?   #                     to the Lambda Function.
#?   #                     The Lambda Functions at local is going to be zipped and
#?   #                     uploaded to S3 Bucket automatically during the deployment.
#?   # Description:
#?   #   Double quote the pairs which contain whitespaces or special characters.
#?   #   Use `#` to comment out.
#?   # ---
#?   # Example:
#?   #   DEPENDS=(
#?   #       S3BucketForLambdaFoo:S3KeyForLambdaFoo=/path/to/LambdaFoo.py
#?   #       S3BucketForLambdaBar:S3KeyForLambdaBar=s3://mybucket/LambdaBar.py
#?   #   )
#?
#?   LAMBDA=()
#?
#?   # LOGICAL_ID=[LogicalId]
#?   #
#?   # Required: No
#?   # Default: None
#?   # Valid Value: Logical resource ID of AWS::EC2::Instance.
#?   # Description:
#?   #   If set this, will try to get the console output of the EC2 Instance
#?   #   over CLI when the stack deployment goes wrong.
#?   # ---
#?   # Example:
#?   #   LOGICAL_ID=WebServerInstance
#?
#?   LOGICAL_ID=
#?
#?   # TIMEOUT=[Minutes]
#?   #
#?   # Required: No
#?   # Default: None
#?   # Valid Value: Integer
#?   # Description:
#?   #   Amount of time that can pass for stack creation.
#?   # ---
#?   # Example:
#?   #   TIMEOUT=5
#?
#?   TIMEOUT=
#?
#?   # OPTIONS=(
#?   #     <ParameterName>=<ParameterValue>
#?   # )
#?   #
#?   # Required: Yes if the template has required parameters, otherwise No
#?   # Default: The parameters for nested templates and Lambda Functions which
#?   #          were defined with `DEPENDS` and `LAMBDA`.
#?   # Syntax:
#?   #   <ParameterName>: The name of template parameters.
#?   #   <ParameterValue>: The value for the parameter.
#?   # Description:
#?   #   The options here will be passed to command `create-stack --parameters`
#?   #   after being translated to the syntax:
#?   #   `ParameterKey=<ParameterName>,ParameterValue=<ParameterValue> ...`
#?   #
#?   #   Double quote the pairs which contain whitespaces or special characters.
#?   #   Use `#` to comment out.
#?   # ---
#?   # Example:
#?   #   OPTIONS=(
#?   #       MyParam=MyValue
#?   #   )
#?
#?   OPTIONS=()
#?
#?   # DISABLE_ROLLBACK=[0 | 1]
#?   #
#?   # Required: No
#?   # Default: Depends on CloudFormation (Rollback on error by default)
#?   # Valid Value:
#?   #   0: Rollback stack on error.
#?   #   1: Disable to rollback stack on error.
#?   # ---
#?   # Example:
#?   #   DISABLE_ROLLBACK=1
#?
#?   DISABLE_ROLLBACK=
#?
#?   # DELETE=[0 | 1]
#?   #
#?   # Required: No
#?   # Default: 0
#?   # Valid Value:
#?   #   0: Do nothing.
#?   #   1: Delete stack after deployment no matter succeeded or failed.
#?   #      Usually set this for test purpose.
#?   # ---
#?   # Example:
#?   #   DELETE=1
#?
#?   DELETE=
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

    function __check_config_version__ () {
        declare version=${1:?}
        # the subshell with `test -n` must be double quoted
        test -n "$(xsh /array/search XSH_AWS_CFN__CFG_SUPPORTED_VERSIONS "$version")"
        return $?
    }

    function __generate_blank_config__ () {
        xsh help -S CONFIG aws/cfn/deploy | sed 's/^  //'
    }

    #? STACK_NAME[-ENVIRONMENT[-RANDOM]]
    function __get_stack_name__ () {

        function __suffix_stack_name__ () {
            declare name=${1:?}

            if [[ -n $ENVIRONMENT ]]; then
                name=$name-$ENVIRONMENT
            fi

            if [[ $RANDOM_STACK_NAME_SUFFIX -eq 1 ]]; then
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
        declare stack_name=${1:?}
        if [[ -n $ENVIRONMENT ]]; then
            xsh /string/lower "${stack_name:?}-${ENVIRONMENT}-cfn-templates"
        else
            xsh /string/lower "${stack_name:?}-cfn-templates"
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

    declare genconf region template config dir update stack_name
    declare -a region_opt options pass_options

    while getopts gr:t:c:p:P:C:DSs:o: opt; do
        case $opt in
            g)
                genconf=1
                ;;
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

    if [[ $genconf -eq 1 ]]; then
        __generate_blank_config__
        return
    fi

    if [[ -z $template ]]; then
        xsh log error "parameter TEMPLATE null or not set."
        return 255
    fi

    # change work dir
    if [[ -n $dir ]]; then
        cd "$dir"
    fi

    # config
    if [[ -n $config ]]; then
        xsh log info "applying config file options: $config..."
        source "$config"

        if __check_config_version__ "${VERSION:-unversioned}"; then
            :
        else
            xsh log error "${VERSION:-unversioned}: the version of config is not supported."
            xsh log info "supported versions are: ${XSH_AWS_CFN__CFG_SUPPORTED_VERSIONS[*]:-undefined}"
            return 255
        fi

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

    declare item depended_uri key value
    for item in "${DEPENDS[@]}"; do
        if [[ -z $item ]]; then
            continue
        fi
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
        if [[ -z $item ]]; then
            continue
        fi
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
        if [[ -z $item ]]; then
            continue
        fi
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
