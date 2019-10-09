#? Description:
#?   Update a CloudFormation stack. Support 2 methods:
#?
#?   1. Create change set for updating a stack.
#?      The execution of change set needs addtional manual step to trigger.
#?
#?   2. Update a stack directly.
#?      This may cause unexpected recreation/replacement of AWS resources.
#?
#? Usage:
#?   @update
#?     -t TEMPLATE | -r
#?     [-s | -d]
#?     [-p POLICY | -P POLICY_DURING_UPDATE]
#?     [<-o KEY=VALUE> ...]
#?     <STACK_ID | STACK_NAME>
#?
#? Options:
#?   -t TEMPLATE
#?
#?   Template file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   If omit this, must give `-r`.
#?
#?   -r
#?
#?   Reuse the existing template that is associated with the stack that is updating.
#?   If omit this, must give `-t TEMPLATE`.
#?
#?   [-s]
#?
#?   Create change set for updating a stack.
#?   The execution of change set needs addtional manual step to trigger.
#?   This is the default option.
#?
#?   [-d]
#?
#?   Directly updates a stack.
#?   This is a DANGER option, which may cause unexpected recreation/replacement
#?   of AWS resources. More safe way: use -s to create change set first, then
#?   execute the change set after the careful review.
#?
#?   [-p POLICY]
#?   Stack policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This option is ignored with change set option `-s`.
#?
#?   [-P POLICY_DURING_UPDATE]
#?   Stack update policy file.
#?   The file must be at local or be a S3 URI starting with `https://`.
#?   This option is ignored with change set option `-s`.
#?
#?   [<-o KEY=VALUE> ...]
#?
#?   The configs here will be passed to command `create-change-set --parameters`
#?   after being translated to the syntax:
#?
#?   `ParameterKey=KEY,ParameterValue=VALUE ...`
#?
#?   <STACK_ID | STACK_NAME>
#?
#?   The name or unique stack ID of the stack that is updating.
#?
function update () {
    local OPTIND OPTARG opt

    local template reuse update stack_policy stack_policy_during_update stack_name
    declare -a options

    while getopts t:rsdp:P:o: opt; do
        case $opt in
            t)
                template=$OPTARG
                ;;
            r)
                reuse=1
                ;;
            s)
                update='changeset'
                ;;
            d)
                update='direct'
                ;;
            p)
                stack_policy=$OPTARG
                ;;
            P)
                stack_policy_during_update=$OPTARG
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
    stack_name=${1:?}

    if [[ -z $template && $reuse -ne 1 ]]; then
        xsh log error "must supply -t TEMPLATE or -r."
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
    )

    if [[ $reuse -eq 1 ]]; then
        options+=( --use-previous-template )
    fi

    local name
    for name in template stack_policy stack_policy_during_update; do
        if [[ -n ${!name} ]]; then
            case $(xsh /uri/parser -s "${!name}" | xsh /string/lower) in
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

    case $update in
        changeset)
            options+=(
                --change-set-name "changeset-$(date '+%Y%m%d-%H%M-%S')"
            )

            aws cloudformation create-change-set "${options[@]}"

            # TODO:
            # 1. Process change set.
            #    * Wait and get change set document.
            #    * Analyze change set document and report to command line.
            #    * Generate URL to changeset console: https://console.amazonaws.cn/cloudformation/home?region=cn-north-1#/changeset/detail?changeSetId=arn:aws-cn:cloudformation:cn-north-1:255522960314:changeSet%2Fchangeset-20160831-0141-000%2F64441228-2b3a-4639-a418-ee08b30f646a
            ;;
        direct)
            aws cloudformation update-stack "${options[@]}"

            # Block to wait stack create complete
            aws cloudformation wait stack-update-complete --stack-name "$stack_name"
            ;;
        *)
            return 255
            ;;
    esac
}
