# shellcheck disable=SC2148

#? Description:
#?   A wrapper script for aws/cfn/vpn/config, aws/cfn/vpn/deploy, aws/cfn/vpn/delete and aws/cfn/vpn/ami.
#?
#? Usage:
#?   @cluster
#?     [-r REGION]
#?     [-x STACKS ...]
#?     <-c CREATE_CLUSTER | -u UPDATE_CLUSTER | -d DELETE_CLUSTER>
#?     [-a]
#?     [-C DIR]
#?
#? Options:
#?   [-r REGION]
#?
#?   The REGION specifies the AWS region name.
#?   Default is using the region in your AWS CLI profile.
#?
#?   [-x STACKS ...]
#?   [-x <00|0-N> ...]
#?
#?   The STACKS specifies the stacks index that will be operated on.
#?
#?   The STACKS option argument is a whitespace separated set of numbers and/or
#?   number ranges. Number ranges consist of a number, a dash ('-'), and a second
#?   number and select the stacks from the first number to the second, inclusive.
#?
#?   The number 0 is specially held for the manager stack, and the rest numbers
#?   started from 1 is for the node stacks.
#?
#?   The string `00` is specially held for a single stack that puts the manager
#?   and the node together.
#?
#?   The manager stack is always being deployed or updated before the node stacks.
#?   The node stacks are always being deleted before the manager stack.
#?
#?   The default STACKS is `00`.
#?
#?   [-c CREATE_CLUSTER]
#?
#?   The CREATE_CLUSTER specifies the name of the new stacks that will be
#?   created.
#?   No stacks are being created if not specified.
#?
#?   [-u UPDATE_CLUSTER]
#?
#?   The UPDATE_CLUSTER specifies the name of the existing stacks that will be
#?   updated.
#?   All config files will be regenerated during the update.
#?
#?   No matter the order of specifying -c, -u, and -d, it always runs in the
#?   order: `-c, -u, -d`.
#?
#?   [-d DELETE_CLUSTER]
#?
#?   The DELETE_CLUSTER specifies the name of the existing stacks that will be
#?   deleted.
#?   No stacks are being deleted if not specified.
#?
#?   [-a]
#?
#?   Update the AMI mapping in the stack.json file.
#?
#?   [-C DIR]
#?
#?   Change the current directory to DIR before doing anything.
#?
#? Example:
#?   # Create an all-in-one stack by using AWS profile `vpn-2021-00`.
#?   $ @cluster -x 00 -c vpn-2021
#?
#?   # Create a cluster with 1 dedicated manager stack and 2 node stacks by
#?     using AWS profile `vpn-2021-0`, `vpn-2021-1`, and `vpn-2021-2`.
#?   $ @cluster -x 0-2 -c vpn-2021
#?
#?   # Update the whole cluster created in the example above.
#?   $ @cluster -x 0-2 -u vpn-2021
#?
#?   # Create a new vpn-2022 cluster, after that delete the old vpn-2021 cluster.
#?   $ @cluster -x 0-2 -c vpn-2022 -d vpn-2021
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function cluster () {

    function __build_options__ () {
        #? Usage:
        #?   __build_options__ <CLUSTER> <REGION> <STACKS>
        #?
        #? Options:
        #?   <CLUSTER>: the cluster name.
        #?   <REGION>: the region name.
        #?   <STACKS>: the stacks index.
        #?
        #? Output:
        #?   The options for the aws/cfn/vpn/config, aws/cfn/vpn/deploy and aws/cfn/vpn/delete.
        #?   The options are saved in the global variables:
        #?     CONFIG_OPTIONS
        #?     CREATE_OPTIONS
        #?     UPDATE_OPTIONS
        #?     DELETE_OPTIONS
        #?
        
        # shellcheck disable=SC2206
        declare cluster=${1:?} stacks=( ${2:?} ) region=$3

        declare profiles names confs env=${XSH_AWS_CFN_VPN_ENV:-sb}
        if [[ ${stacks[0]} == '00' ]]; then
            # single stack
            profiles=( "$cluster-00" )
            names=( "$cluster-00-$env" )
            confs=( "$cluster-00-$env.conf" )
        else
            # multiple stacks
            declare first=0 last
            last=$(xsh /array/last stacks)

            # shellcheck disable=SC2207
            profiles=( $(seq -s ' ' -f "$cluster-%g" "$first" "$last") )
            # shellcheck disable=SC2207
            names=( $(seq -s ' ' -f "$cluster-%g-$env" "$first" "$last") )
            # shellcheck disable=SC2207
            confs=( $(seq -s ' ' -f "$cluster-%g-$env.conf" "$first" "$last") )
        fi

        declare common_options=(
            -r "$region"
            -p "${profiles[@]}"
        )

        CONFIG_OPTIONS=(
            "${common_options[@]}"
            -b "$cluster"
            -e "$env"
            -R
        )

        CREATE_OPTIONS=(
            "${common_options[@]}"
            -c "${confs[@]}"
        )

        UPDATE_OPTIONS=(
            "${common_options[@]}"
            -c "${confs[@]}"
            -s "${names[@]}"
        )

        DELETE_OPTIONS=(
            "${common_options[@]}"
            -s "${names[@]}"
        )
    }


    # main
    declare region stacks=( 00 ) create_cluster update_cluster delete_cluster update_ami dir \
            OPTIND OPTARG opt

    xsh imports /util/getopts/extra /int/range/expand \
                aws/cfn/vpn/config aws/cfn/vpn/deploy aws/cfn/vpn/delete

    while getopts r:x:c:u:d:aC: opt; do
        case $opt in
            r)
                region=$OPTARG
                ;;
            x)
                if [[ $OPTARG == 00 ]]; then
                    stacks=( "$OPTARG" )
                else
                    x-util-getopts-extra "$@"
                    # shellcheck disable=SC2207
                    stacks=( $(x-int-range-expand "${OPTARG[@]}") )
                fi
                ;;
            c)
                create_cluster=$OPTARG
                ;;
            u)
                update_cluster=$OPTARG
                ;;
            d)
                delete_cluster=$OPTARG
                ;;
            a)
                update_ami=1
                ;;
            C)
                dir=${OPTARG:?}
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z ${stacks[*]} || -z $create_cluster$update_cluster$delete_cluster ]]; then
        return 255
    fi

    # change work dir
    if [[ -n $dir ]]; then
        # shellcheck disable=SC2164
        cd "$dir"
    fi

    # update to the latest AMI
    if [[ -n $update_ami ]]; then
        xsh aws/cfn/vpn/ami -t stack.json
    fi

    # below variables are set by __build_options__
    # shellcheck disable=SC2034
    declare -a CONFIG_OPTIONS CREATE_OPTIONS UPDATE_OPTIONS DELETE_OPTIONS

    # create and/or update
    declare operation operation_cluster_varname operation_options_varname
    for operation in create update; do
        operation_cluster_varname="${operation}_cluster"
        operation_options_varname="$(xsh /string/upper "$operation")_OPTIONS[@]"

        if [[ -n ${!operation_cluster_varname} ]]; then
            __build_options__ "${!operation_cluster_varname}" "${stacks[*]}" "$region"

            if [[ ${stacks[0]} == 0 && ${#stacks[@]} -gt 1 ]]; then
                # manager stack goes first
                aws-cfn-vpn-config -x 0 "${CONFIG_OPTIONS[@]}"
                aws-cfn-vpn-deploy -x 0 "${!operation_options_varname}"
                # node stacks goes next
                aws-cfn-vpn-config -x "${stacks[@]:1}" "${CONFIG_OPTIONS[@]}"
                aws-cfn-vpn-deploy -x "${stacks[@]:1}" "${!operation_options_varname}"
            else
                aws-cfn-vpn-config -x "${stacks[@]}" "${CONFIG_OPTIONS[@]}"
                aws-cfn-vpn-deploy -x "${stacks[@]}" "${!operation_options_varname}"
            fi
        fi
    done

    # delete
    if [[ -n $delete_cluster ]]; then
        __build_options__ "$delete_cluster" "${stacks[*]}" "$region"
        aws-cfn-vpn-delete -x "${stacks[@]}" "${DELETE_OPTIONS[@]}"
    fi
}
