# shellcheck disable=SC2148

#? Description:
#?   Deploy AWS CloudFormation VPN stack(s) from template with config file(s).
#?
#?   The script is a high-level wrapper of the `aws/cfn/deploy`. It reduces
#?   the effort to deploy multiple stacks into multiple AWS accounts from the
#?   same template with different config files.
#?
#?   The EC2 key pair names in the config file(s) are dynamically resolved during
#?   the deployment. The deploying region is used as a part of the name to avoid the
#?   potential naming collision. Therefore, the key pairs are automatically
#?   created in AWS and saved to local (~/.ssh) if they don't exist yet.
#?
#? Usage:
#?   @deploy
#?     [-r REGION]
#?     [-x STACKS ...]
#?     [-p PROFILES ...]
#?     [-s NAMES ...]
#?     <-c CONFS ...>
#?     [-C DIR]
#?
#? Options:
#?   [-r REGION]
#?
#?   The REGION specifies the AWS region name.
#?   Default is using the region in your AWS CLI profile.
#?
#?   [-x STACKS ...]
#?   [-x <00|0|1-N> ...]
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
#?   The manager stack is always being deployed before the node stacks.
#?
#?   The default STACKS is `00`.
#?
#?   [-p PROFILES ...]
#?
#?   The PROFILES specifies the candidate of AWS CLI profiles that will be used
#?   to create stacks.
#?   The STACKS option argument is a whitespace separated set of profile names.
#?   The order of the profile names matters.
#?
#?   [-s NAMES ...]
#?
#?   The NAMES specifies the candidate of names of the stacks that will be updated.
#?   If this option presents, the update process is taken rather than the
#?   create process.
#?   The NAMES option argument is a whitespace separated set of stack names.
#?   The order of the stack names matters.
#?
#?   <-c CONFS ...>
#?
#?   The CONFS specifies the candidate of config files that will be operated on.
#?   The CONFS option argument is a whitespace separated set of file names.
#?   The order of the file names matters.
#?
#?   [-C DIR]
#?
#?   Change the current directory to DIR before doing anything.
#?
#? Example:
#?   # Set the environment variables for the base domain and the DNS API:
#?   $ export \
#?     XACVC_BASE_DOMAIN=example.com \
#?     XACVC_XACC_OPTIONS_DomainNameServerEnv=PROVIDER=namecom,LEXICON_PROVIDER_NAME=namecom,LEXICON_NAMECOM_AUTH_USERNAME=your_username,LEXICON_NAMECOM_AUTH_TOKEN=your_token
#?
#?   # Create 1 manager config file using domain plus the DNS API enabled:
#?   $ @config -x 0 -p vpn-{0..2} -R
#?
#?   # Deploy the manager stack:
#?   $ @deploy -x 0 -p vpn-{0..2} -c vpn-{0..2}-sb.conf
#?
#?   # Create 2 node config files using domain plus the DNS API enabled:
#?   $ @config -x 1-2 -p vpn-{0..2} -R
#?
#?   # Deploy the node stacks:
#?   $ @deploy -x 1-2 -p vpn-{0..2} -c vpn-{0..2}-sb.conf
#?
#?   # Update all the stacks deployed in the example above:
#?   $ @deploy -x 0-2 -p vpn-{0..2} -c vpn-{0..2}-sb.conf -s vpn-{0..2}-sb
#?
#? @xsh /trap/err -eE
#? @subshell
#?
#? @xsh imports /int/range/expand /util/getopts/extra
#? @xsh imports aws/cfg/activate aws/ec2/key/exist aws/ec2/key/create aws/cfn/deploy
#?
function deploy () {

    function __get_keypair_name_from_config__ () {
        declare file=${1:?}
        awk -F= '/KeyPairName=/ {print $2}' "$file" | tr -d \'\"
    }

    function __setup_keypair__ () {
        declare name=${1:?} region=${2:?}
        if ! aws-ec2-key-exist -r "$region" "$name"; then
            xsh log info "creating EC2 key pair: $name ..."
            mkdir -p ~/.ssh
            aws-ec2-key-create -r "$region" -f ~/.ssh/"$name" "$name"
        fi
    }

    function __deploy_stack__ () {
        declare conf=${1:?} region=${2:?} name=$3
        if [[ -z $name ]]; then
            xsh log info "creating stack with config: $conf ..."
            aws-cfn-deploy -r "$region" -t stack.json -c "$conf"
        else
            xsh log info "updating stack $name with config: $conf ..."
            echo yes | aws-cfn-deploy -r "$region" -t stack.json -c "$conf" -s "$name" -D
        fi
    }


    # main
    declare region stacks=( 00 ) profiles confs names dir \
            OPTIND OPTARG opt

    while getopts r:x:p:c:s:C: opt; do
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
            p)
                x-util-getopts-extra "$@"
                profiles=( "${OPTARG[@]}" )
                ;;
            c)
                x-util-getopts-extra "$@"
                confs=( "${OPTARG[@]}" )
                ;;
            s)
                x-util-getopts-extra "$@"
                names=( "${OPTARG[@]}" )
                ;;
            C)
                dir=${OPTARG:?}
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z ${stacks[*]} || -z ${confs[*]} ]]; then
        return 255
    fi

    # change work dir
    if [[ -n $dir ]]; then
        # shellcheck disable=SC2164
        cd "$dir"
    fi

    declare stack index profile conf name stack_region keypair_name
    for stack in "${stacks[@]}"; do
        index=$((stack))
        profile=${profiles[index]}
        conf=${confs[index]}
        name=${names[index]}

        if [[ -n $profile ]]; then
            aws-cfg-activate "$profile"
        fi

        if [[ -n $region ]]; then
            stack_region=$region
        else
            stack_region=$(aws configure get default.region)
        fi

        keypair_name=$(__get_keypair_name_from_config__ "$conf")
        __setup_keypair__ "$keypair_name" "$stack_region"
        __deploy_stack__ "$conf" "$stack_region" "$name"
    done
}
