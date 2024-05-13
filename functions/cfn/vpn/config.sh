# shellcheck disable=SC2148

#? Description:
#?   Generate config file(s) for AWS CloudFormation VPN stack(s) from templates. 
#?   The config file(s) can be used by `aws/cfn/vpn/deploy`.
#?   The fundamental syntax of the config is described in the `CONFIG` section of
#?   `xsh aws/cfn/deploy`. Check the document with command: `xsh aws/cfn/deploy -g`.
#?
#? Usage:
#?   @config
#?     [-r REGION]
#?     [-x STACKS ...]
#?     [-p PROFILES ...]
#?     [-b BASE_NAME]
#?     [-e ENVIRONMENT]
#?     [-R]
#?     [-d DOMAIN]
#?     [-n DNS]
#?     [-u DNS_USERNAME]
#?     [-P DNS_CREDENTIAL]
#?     [-i PLUGINS ...]
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
#?   The default STACKS is `00`.
#?
#?   [-p PROFILES ...]
#?
#?   The PROFILES specifies the candidate of AWS CLI profiles that will be used
#?   to generate config.
#?   The STACKS option argument is a whitespace separated set of profile names.
#?   The order of the profile names matters.
#?
#?   [-b BASE_NAME]
#?
#?   The BASE_NAME specifies the base name of stacks.
#?   Default is 'vpn'.
#?
#?   If all goes default, the stack name generated for the config would be `vpn-00-sb`.
#?   During deployment, a random suffix would be add to the stack name as the syntax
#?   `vpn-00-sb-$RANDOM` if it goes without `-R`.
#?
#?   [-e ENVIRONMENT]
#?
#?   The ENVIRONMENT specifies the environment name that is used to generate stack name.
#?   Default is 'sb' which stands for sandbox.
#?
#?   An environment variable `XSH_AWS_CFN_VPN_ENV` can be used to specify the
#?   environment name.
#?
#?   [-R]
#?
#?   Do not add a random suffix to the stack name.
#?   Default is adding a random suffix to the stack name.
#?
#?   [-d DOMAIN]
#?
#?   The DOMAIN specifies the root domain name.
#?   Any subdomain to the root domain must not be included.
#?   For instance, use `example.com` over the FQDN form `vpn.example.com`.
#?   The latter is not acceptable.
#?
#?   An environment variable `XSH_AWS_CFN_VPN_DOMAIN` can be used to specify the
#?   root domain name.
#?
#?   This script uses below rules to derive other domain names and email addresses from the root domain.
#?   If the rules do not meet your requirements, use the corresponding environment variables
#?   to override the values. The new values must share the same root domain with DOMAIN.
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?   | Purpose             | Type   |   Prefix | + | Root Domain | Environment Variable to Override |
#?   +=====================+========+==========+===+=============+==================================+
#?   | SSM administrator   | Email  |    admin | @ | example.com | XSH_AWS_CFN_VPN_SSM_ADMIN_EMAIL  |
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?   | SSM service         | Domain | admin.ss | . | example.com | XSH_AWS_CFN_VPN_SSM_DOMAIN       |
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?   | L2TPD service       | Domain |      vpn | . | example.com | XSH_AWS_CFN_VPN_L2TP_DOMAIN      |
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?   | Shadowsocks service | Domain |       ss | . | example.com | XSH_AWS_CFN_VPN_SS_DOMAIN        |
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?   | Shadowsocks service | Domain | v2ray.ss | . | example.com | XSH_AWS_CFN_VPN_SS_DOMAIN        |
#?   +---------------------+--------+----------+---+-------------+----------------------------------+
#?
#?   The environment variables above are ignored if root domain is not set.
#?
#?   [-n DNS]
#?
#?   The DNS specifies the Domain Nameserver for the DOMAIN.
#?   Supported Nameserver: 'name.com'.
#?   This option is ignored if `-d DOMAIN` or `XSH_AWS_CFN_VPN_DOMAIN` is not set.
#?
#?   An environment variable `XSH_AWS_CFN_VPN_DNS` can be used to specify the
#?   Domain Nameserver.
#?
#?   [-u DNS_USERNAME]
#?
#?   The DNS_USERNAME specifies the user identity for the Domain Nameserver API service.
#?   This option is ignored if `-d DOMAIN` or `XSH_AWS_CFN_VPN_DOMAIN` is not set.
#?
#?   An environment variable `XSH_AWS_CFN_VPN_DNS_USERNAME` can be used to specify the
#?   user identity.
#?
#?   [-P DNS_CREDENTIAL]
#?
#?   The DNS_CREDENTIAL specifies the user credential/token for the Domain Nameserver API service.
#?   This option is ignored if `-d DOMAIN` or `XSH_AWS_CFN_VPN_DOMAIN` is not set.
#?
#?   An environment variable `XSH_AWS_CFN_VPN_DNS_CREDENTIAL` can be used to specify the
#?   user credential/token.
#?
#?   The `DNS*` options are essential to automate the DNS record management. They are used
#?   in several places depending on you configuration:
#?
#?   +---------------------+-------------------+---------------------------------------------------------------------------+
#?   | Used by             | Used on           | Used for                                                                  |
#?   +=====================+===================+===========================================================================+
#?   | shadowsocks-manager | Manager stack     | Publishing DNS records for web console, L2TPD and Shadowsocks nodes       |
#?   +---------------------+-------------------+---------------------------------------------------------------------------+
#?   | AWS Lambda          | AWS               | Issuing TLS certificate in AWS ACM to enable HTTPS on ELB for web console |
#?   +---------------------+-------------------+---------------------------------------------------------------------------+
#?   | acme.sh             | Shadowsocks nodes | Issuing TLS certificate for v2ray-plugin if it's enabled                  |
#?   +---------------------+-------------------+---------------------------------------------------------------------------+
#?
#?   [-i PLUGINS ...]
#?
#?   The PLUGINS specifies the Shadowsocks plugins that will be enabled in the config.
#?   The PLUGINS option argument is a whitespace separated set of plugin names.
#?   Supported plugins:
#?
#?   - v2ray
#?
#?     This is ignored if `-d DOMAIN` or `XSH_AWS_CFN_VPN_DOMAIN` is not set.
#?
#?   [-C DIR]
#?
#?   Change the current directory to DIR before doing anything.
#?
#? Environment:
#?   The following environment variables are optionally looked up to generate config:
#?
#?   - XSH_AWS_CFN_VPN_ENV
#?   - XSH_AWS_CFN_VPN_DOMAIN
#?   - XSH_AWS_CFN_VPN_DNS
#?   - XSH_AWS_CFN_VPN_DNS_USERNAME
#?   - XSH_AWS_CFN_VPN_DNS_CREDENTIAL
#?   - XSH_AWS_CFN_VPN_PLUGINS
#?
#?   - XSH_AWS_CFN_VPN_SSM_ADMIN_EMAIL
#?   - XSH_AWS_CFN_VPN_SSM_DOMAIN
#?   - XSH_AWS_CFN_VPN_L2TP_DOMAIN
#?   - XSH_AWS_CFN_VPN_SS_DOMAIN
#?
#?   The command line options take precedence over environment variables if both are set.
#?
#? Template:
#?   The config file is generated from the templates in the `config-templates` directory.
#?   The template file names are in the following format:
#?
#?   - [DEPENDS|LAMBDA|LOGICAL_ID|OPTIONS]-[COMMON|00|0|1].conf
#?
#? Example:
#?   # Create 1 manager config file using domain plus the Nameserver API enabled:
#?   $ @config -x 0 -p vpn-{0..2} -R -d example.com -n name.com -u myuser -P mytoken
#?
#?   # Deploy the manager stack:
#?   $ @deploy -x 0 -p vpn-{0..2} -c vpn-{0..2}-sb.conf
#?
#?   # Create 2 node config files using domain plus the Nameserver API enabled:
#?   $ @config -x 1-2 -p vpn-{0..2} -R -d example.com -n name.com -u myuser -P mytoken
#?
#?   # Deploy the node stacks:
#?   $ @deploy -x 1-2 -p vpn-{0..2} -c vpn-{0..2}-sb.conf
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function config () {

    function __init_config__ () {
        declare file=${1:?} stack=${2:?}

        xsh log info "generating config file: $file ..."
        aws-cfn-deploy -g > "$file"

        # +-------+----+
        # | stack | n  |
        # +=======+====+
        # | 00    | 00 |
        # +-------+----+
        # | 0     | 0  |
        # +-------+----+
        # | > 0   | 1  |
        # +-------+----+
        declare n=$stack
        if [[ $n -gt 0 ]]; then
            n=1
        fi

        # update DEPENDS LAMBDA LOGICAL_ID OPTIONS
        declare param
        for param in DEPENDS LAMBDA LOGICAL_ID OPTIONS; do
            xsh log info "> updating $param ..."
            x-util-sed-inplace "/^$param=[^\"]*/ {
                                    r /dev/stdin
                                    d
                                }" "$file" \
                <<< "$(cat "config-templates/$param-COMMON.conf" \
                        "config-templates/$param-$n.conf")"
        done
    }

    function __update_config__ () {
        # shellcheck disable=SC2206
        declare file=${1:?} stack=${2:?} base_name=${3:?} env=${4:?} random=${5:?} \
                domain=$6 dns=$7 dns_username=$8 dns_credential=$9 v2ray=${10} \
                ssm_admin_email=${11} ssm_domain=${12} l2tp_domain=${13} ss_domain=${14} \
                region=${15:?}

        xsh log info "updating config file: $file ..."

        # shellcheck disable=SC2034
        declare STACK_NAME=$base_name-$stack \
                ENVIRONMENT=$env \
                RANDOM_STACK_NAME_SUFFIX=$random

        # update:
        #   STACK_NAME ENVIRONMENT RANDOM_STACK_NAME_SUFFIX
        declare param
        for param in STACK_NAME ENVIRONMENT RANDOM_STACK_NAME_SUFFIX; do
            xsh log info "> updating $param ..."
            x-util-sed-inplace "s|^$param=[^\"]*|$param=${!param}|" "$file"
        done

        # shellcheck disable=SC2034
        declare KeyPairName="aws-ek-$base_name-$stack-$env-$region" \
                Domain DomainNameServer DomainNameServerUsername DomainNameServerCredential EnableV2ray \
                SSMAdminEmail SSMDomain L2TPDomain SSDomain

        # shellcheck disable=SC2034
        if [[ -n $domain ]]; then
            Domain=$domain
            DomainNameServer=$dns
            DomainNameServerUsername=$dns_username
            DomainNameServerCredential=$dns_credential
            EnableV2ray=$v2ray
            SSMAdminEmail=$ssm_admin_email
            SSMDomain=$ssm_domain
            L2TPDomain=$l2tp_domain
            SSDomain=$ss_domain
        fi

        # update OPTIONS:
        #   KeyPairName Domain DomainNameServer DomainNameServerUsername DomainNameServerCredential EnableV2ray
        #   SSMAdminEmail SSMDomain L2TPDomain SSDomain
        for param in KeyPairName Domain DomainNameServer DomainNameServerUsername DomainNameServerCredential EnableV2ray \
                SSMAdminEmail SSMDomain L2TPDomain SSDomain; do
            xsh log info "> updating OPTIONS: $param ..."
            # (^\|[^a-zA-Z0-9_]): to match word boundary, for both GNU and BSD sed
            x-util-sed-regex-inplace "s|(^\|[^a-zA-Z0-9_])$param=[^\"]*|\1$param=${!param}|" "$file"
        done

        # update OPTIONS:
        #   VpcCidrBlock SubnetCidrBlocks
        xsh log info "> updating OPTIONS: VpcCidrBlock SubnetCidrBlocks ..."
        x-util-sed-inplace "/CidrBlock/ s|<N>|$((stack))|g" "$file"
    }

    function __update_node_config__ () {
        declare file=${1:?} stack=${2:?} mgr_stack_json=${3:?}

        xsh log info "updating node config file: $file ..."

        declare item output_key input_key value
        for item in "${XSH_AWS_CFN_VPN__PARAM_MAPPINGS_MGR_OUTPUT_TO_NODE_INPUT[@]}"; do
            output_key=${item%%:*}
            input_key=${item##*:}
            value="$(aws-cfn-stack-output-get "$mgr_stack_json" "$output_key")"
            xsh log info "> updating OPTIONS: $input_key ..."
            # (^\|[^a-zA-Z0-9_]): to match word boundary, for both GNU and BSD sed
            x-util-sed-regex-inplace "s|(^\|[^a-zA-Z0-9_])${input_key}=[^\"]*|\1${input_key}=${value}|" "$file"
        done
    }

    function __guess_stack_name__ () {
        declare base_name=${1:?} region=${2:?}

        # guess the stack name by looking up the existing stacks in running status
        aws-cfn-stack-list \
            -r "$region" \
            -s "${XSH_AWS_CFN__STACK_STATUS_SERVICEABLE[@]}" \
            -q "[?StackName >= '$base_name-0' && StackName <= '$base_name-32767'].StackName | [0] || []" \
            -o text
    }


    # main
    declare region \
            stacks=( 00 ) \
            profiles \
            base_name=vpn \
            env=${XSH_AWS_CFN_VPN_ENV:-sb} \
            random=1 \
            domain=${XSH_AWS_CFN_VPN_DOMAIN} \
            dns=${XSH_AWS_CFN_VPN_DNS} \
            dns_username=${XSH_AWS_CFN_VPN_DNS_USERNAME} \
            dns_credential=${XSH_AWS_CFN_VPN_DNS_CREDENTIAL} \
            plugins=( "${XSH_AWS_CFN_VPN_PLUGINS[@]}" ) \
            v2ray=0 \
            dir \
            OPTIND OPTARG opt

    xsh imports /util/getopts/extra /int/range/expand \
                /util/sed-inplace /util/sed-regex-inplace /string/lower \
                aws/cfg/activate aws/cfn/stack/list aws/cfn/stack/output/get \
                aws/cfn/deploy aws/cfn/stack/desc

    while getopts r:x:p:b:e:Rd:n:u:P:i:C: opt; do
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
            b)
                base_name=$OPTARG
                ;;
            e)
                env=$OPTARG
                ;;
            R)
                random=0
                ;;
            d)
                domain=$(x-string-lower "$OPTARG")
                ;;
            n)
                dns=$OPTARG
                ;;
            u)
                dns_username=$OPTARG
                ;;
            P)
                dns_credential=$OPTARG
                ;;
            i)
                x-util-getopts-extra "$@"
                plugins=( "${OPTARG[@]}" )
                ;;
            C)
                dir=${OPTARG:?}
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z ${stacks[*]} ]]; then
        return 255
    fi

    # change work dir
    if [[ -n $dir ]]; then
        # shellcheck disable=SC2164
        cd "$dir"
    fi

    # check if need to generate the manager stack config
    declare if_mgr_stack_conf=0
    if [[ ${stacks[0]} == 0 ]]; then
        # generate the manager stack config
        if_mgr_stack_conf=1
    elif [[ ${stacks[0]} == 00 ]]; then
        :
    elif [[ ${stacks[0]} -gt 0 ]]; then
        # insert the manager stack to the head
        stacks=( 0 "${stacks[@]}" )
    fi

    # check if need to generate the manager stack json
    declare if_mgr_stack_json=0
    if [[ ${#stacks[@]} -gt 1 ]]; then
        # generate the manager stack json
        if_mgr_stack_json=1
    fi

    # plugins
    declare plugin
    for plugin in "${plugins[@]}"; do
        case $plugin in
            v2ray)
                v2ray=1
                ;;
            *)
                xsh log warning "unsupported plugin: $plugin"
                ;;
        esac
    done

    # apply the derive rules for domains and email address if the root domain is set
    if [[ -n $domain ]]; then
        ssm_admin_email=${XSH_AWS_CFN_VPN_SSM_ADMIN_EMAIL:-admin@$domain}
        ssm_domain=${XSH_AWS_CFN_VPN_SSM_DOMAIN:-admin.ss.$domain}
        l2tp_domain=${XSH_AWS_CFN_VPN_L2TP_DOMAIN:-vpn.$domain}

        if [[ $v2ray -eq 1 ]]; then
            ss_domain=${XSH_AWS_CFN_VPN_SS_DOMAIN:-v2ray.ss.$domain}
        else
            ss_domain=${XSH_AWS_CFN_VPN_SS_DOMAIN:-ss.$domain}
        fi
    fi

    # loop the list to generate config files
    declare stack index profile stack_name stack_region mgr_stack_json file
    for stack in "${stacks[@]}"; do
        index=$((stack))
        profile=${profiles[index]}
        stack_name=$base_name-$stack-$env

        if [[ -n $profile ]]; then
            aws-cfg-activate "$profile"
        fi

        if [[ -n $region ]]; then
            stack_region=$region
        else
            stack_region=$(aws configure get default.region)
        fi

        # get the manager stack info
        if [[ $stack == 0 && if_mgr_stack_json -eq 1 ]]; then
            declare mgr_stack_name
            if [[ $random -eq 0 ]]; then
                mgr_stack_name=$stack_name
            else
                # guess the manager stack name
                mgr_stack_name=$(__guess_stack_name__ "$stack_name" "$stack_region")
                if [[ -z $mgr_stack_name ]]; then
                    xsh log warning "failed to guess the manager stack name."
                fi
            fi

            if [[ -n $mgr_stack_name ]]; then
                # get the manager stack info
                mgr_stack_json=$(aws-cfn-stack-desc -r "$stack_region" -s "$mgr_stack_name")
                if [[ -z $mgr_stack_json ]]; then
                    xsh log warning "$mgr_stack_name: failed to get the manager stack info."
                fi
            fi
        fi

        # skip the manager stack config
        if [[ $stack == 0 && $if_mgr_stack_conf -eq 0 ]]; then
            continue
        fi

        # generate the config file
        file=$stack_name.conf
        __init_config__ "$file" "$stack"
        __update_config__ "$file" "$stack" "$base_name" "$env" "$random" \
            "$domain" "$dns" "$dns_username" "$dns_credential" "$v2ray" \
            "$ssm_admin_email" "$ssm_domain" "$l2tp_domain" "$ss_domain" \
            "$stack_region"

        # update the node config file with the output of the manager stack
        if [[ $stack -gt 0 && -n $mgr_stack_json ]]; then
            __update_node_config__ "$file" "$stack" "$mgr_stack_json"
        fi
    done
}
