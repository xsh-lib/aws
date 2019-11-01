#? Description:
#?   Create AWS CloudFormation stack from template.
#?
#? Usage:
#?   @create
#?     [-r REGION]
#?     -s STACK_NAME
#?     -t TEMPLATE
#?     [-p POLICY]
#?     [-R]
#?     [-w TIMEOUT]
#?     [<-o KEY=VALUE> ...]
#?
#? Options
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   -s STACK_NAME
#?
#?   The name for the stack.
#?   The name must be unique in the region in which you are creating the stack.
#?
#?   -t TEMPLATE
#?
#?   Template file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?
#?   [-p POLICY]
#?
#?   Stack policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?
#?   [-R]
#?   If set, will disable rollback of the stack when stack creation failed.
#?
#?   [-w TIMEOUT]
#?   In minutes, amount of time that can pass for creating the stack.
#?
#?   [<-o KEY=VALUE> ...]
#?
#?   This option is past through to `create-stack --parameters`.
#?
function create () {
    declare OPTIND OPTARG opt

    declare -a region_opt options pass_options
    declare stack_name stack_policy template

    while getopts r:s:t:p:w:Ro: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            s)
                stack_name=$OPTARG
                ;;
            t)
                template=$OPTARG
                ;;
            p)
                stack_policy=$OPTARG
                ;;
            R)
                pass_options+=( --disable-rollback )
                ;;
            w)
                pass_options+=( --timeout-in-minutes "${OPTARG:?}" )
                ;;
            o)
                # `KEY=VALUE` to `ParameterKey=KEY,ParameterValue=VALUE`
                OPTARG=${OPTARG/=/,ParameterValue=}
                OPTARG=${OPTARG/#/ParameterKey=}

                options+=( "$OPTARG" )
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $stack_name ]]; then
        xsh log error "parameter STACK_NAME null or not set."
        return 255
    fi

    # --parameters options
    if [[ -n ${options[@]} ]]; then
        options=( --parameters "${options[@]}" )
    fi

    options+=(
        --stack-name "$stack_name"

        # always set this in case of creating IAM user
        --capabilities CAPABILITY_IAM
        --capabilities CAPABILITY_NAMED_IAM

        "${pass_options[@]}"
    )

    declare name
    for name in template stack_policy; do
        if [[ -n ${!name} ]]; then
            case $(xsh /uri/parser -s "${!name}" | xsh /string/pipe/lower) in
                http|https)
                    options+=( "--${name//_/-}-url" "${!name}" )
                    ;;
                '')
                    options+=( "--${name//_/-}-body" "$(cat "${!name}")" )
                    ;;
                *)
                    return 255
                    ;;
            esac
        fi
    done

    # create Stack
    aws "${region_opt[@]}" cloudformation create-stack "${options[@]}" && \
        # block to wait stack create complete
        aws "${region_opt[@]}" cloudformation wait stack-create-complete --stack-name "$stack_name"
}
