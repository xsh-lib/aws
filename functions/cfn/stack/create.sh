#? Description:
#?   Create AWS CloudFormation stack from template.
#?
#? Usage:
#?   @create
#?     -n STACK_NAME
#?     [-p POLICY]
#?     [-R]
#?     [-w TIMEOUT]
#?     [<-o KEY=VALUE> ...]
#?     TEMPLATE
#?
#? Options
#?   -n STACK_NAME
#?
#?   The name for the stack.
#?   The name must be unique in the region in which you are creating the stack.
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
#?   TEMPLATE
#?
#?   Template file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?
function create () {
    local OPTIND OPTARG opt

    local stack_name stack_policy template
    declare -a options pass_options

    while getopts n:p:w:Ro: opt; do
        case $opt in
            n)
                stack_name=$OPTARG
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
    shift $((OPTIND - 1))
    template=${1:?}

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

    local name
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
    aws cloudformation create-stack "${options[@]}" && \
        # block to wait stack create complete
        aws cloudformation wait stack-create-complete --stack-name "$stack_name"
}
