# shellcheck disable=SC2148

#? Description:
#?   Delete AWS CloudFormation VPN stack(s).
#?   The key pairs won't be deleted along with the stacks.
#?
#? Usage:
#?   @delete
#?     [-r REGION]
#?     [-x STACKS ...]
#?     [-p PROFILES ...]
#?     <-s NAMES ...>
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
#?   The node stacks are always being deleted before the manager stack.
#?
#?   The default STACKS is `00`.
#?
#?   [-p PROFILES ...]
#?
#?   The PROFILES specifies the candidate of AWS CLI profiles that will be used
#?   to delete stacks.
#?   The STACKS option argument is a whitespace separated set of profile names.
#?   The order of the profile names matters.
#?
#?   <-s NAMES ...>
#?
#?   The NAMES specifies the candidate names of the stacks that will be deleted.
#?   The NAMES option argument is a whitespace separated set of stack names.
#?   The order of the stack names matters.
#?
#? Example:
#?   # Delete the manager stack and the node stacks.
#?   @delete -x {0..2} -p vpn-{0..2} -s vpn-{0..2}-sb
#?
#? @xsh /trap/err -eE
#? @subshell
#?
#? xsh imports /int/range/expand /util/getopts/extra
#? xsh imports aws/cfg/activate aws/cfn/stack/delete
#?
function delete () {
    declare region stacks=( 00 ) profiles names \
            OPTIND OPTARG opt

    while getopts r:x:p:s: opt; do
        case $opt in
            r)
                region=$OPTARG
                ;;
            x)
                if [[ $OPTARG == 00 ]]; then
                    stacks=( "$OPTARG" )
                else
                    x-util-getopts-extra "$@"
                    # sorting in DESC order, make sure the manager stack is processed at the last
                    # shellcheck disable=SC2207
                    stacks=( $(x-int-range-expand -r "${OPTARG[@]}") )
                fi
                ;;
            p)
                x-util-getopts-extra "$@"
                profiles=( "${OPTARG[@]}" )
                ;;
            s)
                x-util-getopts-extra "$@"
                names=( "${OPTARG[@]}" )
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z ${stacks[*]} || -z ${names[*]} ]]; then
        return 255
    fi

    # loop the list to delete stacks
    declare stack index profile name stack_region
    for stack in "${stacks[@]}"; do
        index=$((stack))
        profile=${profiles[index]}
        name=${names[index]}

        if [[ -n $profile ]]; then
            aws-cfg-activate "$profile"
        fi

        if [[ -n $region ]]; then
            stack_region=$region
        else
            stack_region=$(aws configure get default.region)
        fi

        xsh log info "deleting stack: $name ..."
        aws-cfn-stack-delete -r "$stack_region" -s "$name"
    done
}
