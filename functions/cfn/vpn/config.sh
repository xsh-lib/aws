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
#?     [-d BASE_DOMAIN]
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
#?   This option overrides the environment variable: `XACVC_XACC_ENVIRONMENT`.
#?
#?   [-R]
#?
#?   Do not add a random suffix to the stack name.
#?   Default is adding a random suffix to the stack name.
#?
#?   This option overrides the environment variable: `XACVC_XACC_RANDOM_STACK_NAME_SUFFIX`.
#?
#?   [-d BASE_DOMAIN]
#?
#?   The BASE_DOMAIN specifies the base domain name for deriving other domain names.
#?   No default value.
#?
#?   This option overrides the environment variable: `XACVC_BASE_DOMAIN`.
#?
#?   The following rules are applied to derive the domain names:
#?   If the rules do not meet your requirements, use the corresponding environment variables
#?   to override the values.
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?   | Target           | Type   | Prefix   | + | Base Domain | Overridable with                 |
#?   +==================+========+==========+===+=============+==================================+
#?   | SSMAdminEmail    | Email  | admin    | @ | example.com | XACVC_XACC_OPTIONS_SSMAdminEmail |
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?   | SSMDomain        | Domain | admin.ss | . | example.com | XACVC_XACC_OPTIONS_SSMDomain     |
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?   | SSDomain         | Domain | ss       | . | example.com | XACVC_XACC_OPTIONS_SSDomain      |
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?   | SSDomain (V2Ray) | Domain | v2ray.ss | . | example.com | XACVC_XACC_OPTIONS_SSDomain      |
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?   | L2TPDomain       | Domain | vpn      | . | example.com | XACVC_XACC_OPTIONS_L2TPDomain    |
#?   +------------------+--------+----------+---+-------------+----------------------------------+
#?
#?   The domain names can have different root domains or different zone names, regardless of whether
#?   they are sharing the same DNS provider or credentials.
#?
#?   In most cases, the zone name of a domain name is the same as the root domain name. But with the
#?   delegated subdomain, the domain names direved from the subdomain have different zone name from
#?   the root domain name. For the sake of this complexity, the zone names for all the domain names
#?   are dynamically resolved during the deployment.
#?
#?   [-C DIR]
#?
#?   Change the current directory to DIR before doing anything.
#?
#? Environment:
#?   TODO: a better way to document the environment variables
#?   The following environment variables are optionally looked up to generate config.
#?   The command line options take precedence over environment variables if both are set.
#?
#?   - XACVC_BASE_DOMAIN
#?   - XACVC_XACC_ENVIRONMENT
#?   - XACVC_XACC_RANDOM_STACK_NAME_SUFFIX
#?
#?   The following environment variables are optionally looked up to generate config.
#?   The environment variables take precedence over the default values if set.
#?
#?   - XACVC_XACC_STACK_NAME
#?
#?   - XACVC_XACC_OPTIONS_InstanceType
#?   - XACVC_XACC_OPTIONS_KeyPairName
#?   - XACVC_XACC_OPTIONS_DomainNameServerEnv
#?
#?   - XACVC_XACC_OPTIONS_SSMAdminUsername
#?   - XACVC_XACC_OPTIONS_SSMAdminPassword
#?   - XACVC_XACC_OPTIONS_SSMAdminEmail
#?   - XACVC_XACC_OPTIONS_SSMTimeZone
#?   - XACVC_XACC_OPTIONS_SSMVersion
#?   - XACVC_XACC_OPTIONS_SSMDomain
#?   - XACVC_XACC_OPTIONS_SSMDomainNameServerEnv
#?
#?   - XACVC_XACC_OPTIONS_SSManagerInterface
#?   - XACVC_XACC_OPTIONS_SSManagerPort
#?   - XACVC_XACC_OPTIONS_SSEncrypt
#?   - XACVC_XACC_OPTIONS_SSTimeout
#?   - XACVC_XACC_OPTIONS_SSPortBegin
#?   - XACVC_XACC_OPTIONS_SSPortEnd
#?   - XACVC_XACC_OPTIONS_SSV2Ray
#?   - XACVC_XACC_OPTIONS_SSVersion
#?   - XACVC_XACC_OPTIONS_SSDomain
#?   - XACVC_XACC_OPTIONS_SSDomainNameServerEnv
#?
#?   - XACVC_XACC_OPTIONS_L2TPUsername
#?   - XACVC_XACC_OPTIONS_L2TPPassword
#?   - XACVC_XACC_OPTIONS_L2TPSharedKey
#?   - XACVC_XACC_OPTIONS_L2TPDomain
#?   - XACVC_XACC_OPTIONS_L2TPDomainNameServerEnv
#?   - XACVC_XACC_OPTIONS_L2TPPrimaryDNS
#?   - XACVC_XACC_OPTIONS_L2TPSecondaryDNS
#?
#?   - XACVC_XACC_OPTIONS_DomainNameServerEnv
#?
#?     The XACVC_XACC_OPTIONS_DomainNameServerEnv specifies the environment variables required to use the DNS API service.
#?     No default value.
#?
#?     Syntax: `PROVIDER={dns_provider},LEXICON_PROVIDER_NAME={dns_provider},LEXICON_{DNS_PROVIDER}_{OPTION}={value}[,...]`
#?
#?     The Python library `dns-lexicon` is leveraged to parse the DNS_ENV and access the DNS API.
#?     The required {OPTION} depends on the {dns_provider} that you use.
#?     For the list of supported {dns_provider} and {OPTION} please refer to:
#?     * https://dns-lexicon.readthedocs.io/en/latest/configuration_reference.html
#?
#?     Speciallly, an extra environment variable `PROVIDER` is used to repeat the {dns_provider} for
#?     the convenience of using the DNS_ENV in `acme.sh` with the `--dns dns_lexicon` option.
#?     * https://github.com/acmesh-official/acme.sh/wiki/dnsapi
#?     * https://github.com/acmesh-official/acme.sh/wiki/How-to-use-lexicon-DNS-API
#?
#?     Sample: `PROVIDER=namecom,LEXICON_PROVIDER_NAME=namecom,LEXICON_NAMECOM_AUTH_USERNAME=your_username,LEXICON_NAMECOM_AUTH_TOKEN=your_token`
#?
#?     XACVC_XACC_OPTIONS_DomainNameServerEnv is defaultly used to access the DNS API for all the domain names: `XACVC_XACC_OPTIONS_[SSM|SS|L2TP]Domain`.
#?     If some domain names require different settings from the default, the corresponding environment
#?     variables can be used to override the default: `XACVC_XACC_OPTIONS_[SSM|SS|L2TP]DomainNameServerEnv`.
#?
#?     This option is essential to automate the DNS record management. They are used
#?     in several places depending on you configuration:
#?
#?     +-------------------------+----------------------------+-------------------------+---------------------------+----------------------+-----------------+------------------+
#?     | Project                 | Component                  | DNS Library             | Usage                     | Purpose              | Impacted Domain | Impacted Feature |
#?     +=========================+============================+=========================+===========================+======================+=================+==================+
#?     | shadowsocks-manager     | docker-entrypoint.sh       | acme.sh => dns-lexicon  | domain owner verification | issuing certificates | SSMDomain       | Nginx HTTPS      |
#?     +-------------------------+----------------------------+-------------------------+---------------------------+----------------------+-----------------+------------------+
#?     | shadowsocks-manager     | domain/models.py           | dns-lexicon             | DNS record management     | DNS record sync      | SSMDomain       | DNS record sync  |
#?     |                         |                            |                         |                           |                      | SSDomain        |                  |
#?     |                         |                            |                         |                           |                      | L2TPDomain      |                  |
#?     +-------------------------+----------------------------+-------------------------+---------------------------+----------------------+-----------------+------------------+
#?     | shadowsocks-libev-v2ray | docker-entrypoint.sh       | acme.sh => dns-lexicon  | domain owner verification | issuing certificates | SSDomain        | v2ray-plugin     |
#?     +-------------------------+----------------------------+-------------------------+---------------------------+----------------------+-----------------+------------------+
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
#? @xsh imports /int/range/expand /string/lower /util/getopts/extra /util/sed-inplace /util/sed-regex-inplace
#? @xsh imports aws/cfg/activate aws/cfn/stack/list aws/cfn/stack/desc aws/cfn/stack/output/get aws/cfn/deploy
#?
function config () {

    function __get_stack_type__ () {
        #? Description:
        #?   Get the stack type by the stack index.
        #?
        #? Rule:
        #?   +-------+----+------+
        #?   | Index | to | Type |
        #?   +=======+====+======+
        #?   | 00    | => | 00   |
        #?   +-------+----+------+
        #?   | 0     | => | 0    |
        #?   +-------+----+------+
        #?   | >= 1  | => | 1    |
        #?   +-------+----+------+
        #?
        declare stack=${1:?}
        if [[ $stack -gt 0 ]]; then
            echo 1
        else
            echo "$stack"
        fi
    }

    function __replace_option_value_by_name__ () {
        #? Description:
        #?   Replace the value of the option by the name in the config file.
        #?
        #? Usage:
        #?   __replace_option_value_by_name__ FILE NAME VALUE
        #?
        #? Regexp:
        #?   (^\|[^a-zA-Z0-9_])
        #?     * match word boundary
        #?     * works for both GNU and BSD sed
        #?
        #?   [^a-zA-Z0-9_-@%+:.]
        #?     * match any character except a-zA-Z0-9_-@%+:.
        #?     * if the value contains any characters other than the patten, it will be single quoted.
        #?
        declare file=${1:?} name=${2:?} value=$3
        declare csq # conditionally single quote the value

        if [[ "$value" =~ [^-0-9a-zA-Z@%_+:.] ]]; then
            csq="'"
        fi
        x-util-sed-regex-inplace "s|(^\|[^a-zA-Z0-9_])${name}=[^\"]*|\1${name}=${csq}${value}${csq}|" "$file"
    }

    function __init_config__ () {
        declare file=${1:?} stack=${2:?}

        xsh log info "generating config file: $file ..."
        aws-cfn-deploy -g > "$file"

        declare stack_type
        stack_type=$(__get_stack_type__ "$stack")

        # update DEPENDS LAMBDA LOGICAL_ID OPTIONS
        declare param
        for param in DEPENDS LAMBDA LOGICAL_ID OPTIONS; do
            xsh log info "> updating $param ..."
            x-util-sed-inplace "/^$param=[^\"]*/ {
                                    r /dev/stdin
                                    d
                                }" "$file" \
                <<< "$(cat "config-templates/$param-COMMON.conf" \
                        "config-templates/$param-$stack_type.conf")"
        done
    }

    function __update_config__ () {
        declare file=${1:?} stack=${2:?} base_name=${3:?} region=${4:?}

        xsh log info "updating config file: $file ..."

        # use subshell to volatilize the modifications for the variables to the caller
        (
            # shellcheck disable=SC2034
            declare STACK_NAME=$base_name-$stack

            __set_to_prefix_if_prefix_is_empty__ XACVC_XACC_ STACK_NAME

            # update
            declare var config_var
            for var in "${XSH_AWS_CFN_VPN__CONFIG_VARS[@]}"; do
                config_var=${var#XACVC_XACC_}
                xsh log info "> updating $config_var ..."
                x-util-sed-inplace "s|^$config_var=[^\"]*|$config_var=${!var}|" "$file"
            done

            declare stack_type
            stack_type=$(__get_stack_type__ "$stack")

            # shellcheck disable=SC2034
            declare KeyPairName="aws-ek-$base_name-$stack-$XACVC_XACC_ENVIRONMENT-$region"

            __set_to_prefix_if_prefix_is_empty__ XACVC_XACC_OPTIONS_ KeyPairName

            if [[ ( $stack_type == 0 && ( -n $XACVC_XACC_OPTIONS_SSMDomainNameServerEnv && -n $XACVC_XACC_OPTIONS_L2TPDomainNameServerEnv ) ) || \
                  ( $stack_type == 1 && -n $XACVC_XACC_OPTIONS_SSDomainNameServerEnv ) || \
                  ( $stack_type == 00 && ( -n $XACVC_XACC_OPTIONS_SSMDomainNameServerEnv && -n $XACVC_XACC_OPTIONS_L2TPDomainNameServerEnv && -n $XACVC_XACC_OPTIONS_SSDomainNameServerEnv ) ) ]]; then
                unset XACVC_XACC_OPTIONS_DomainNameServerEnv
            fi

            if [[ $stack_type == 0 ]]; then
                unset XACVC_XACC_OPTIONS_SSDomain XACVC_XACC_OPTIONS_SSDomainNameServerEnv \
                      XACVC_XACC_OPTIONS_SSV2Ray
            fi

            if [[ $stack_type == 1 ]]; then
                unset XACVC_XACC_OPTIONS_SSMAdminEmail XACVC_XACC_OPTIONS_SSMDomain \
                      XACVC_XACC_OPTIONS_SSMDomainNameServerEnv XACVC_XACC_OPTIONS_L2TPDomain \
                      XACVC_XACC_OPTIONS_L2TPDomainNameServerEnv
            fi

            # update OPTIONS
            for var in "${XSH_AWS_CFN_VPN__CONFIG_OPTIONS_VARS[@]}"; do
                # skip to update the options if the global env is not declared
                if ! declare -p "$var" &>/dev/null; then
                    continue
                fi

                config_var=${var#XACVC_XACC_OPTIONS_}
                xsh log info "> updating OPTIONS: $config_var ..."
                __replace_option_value_by_name__ "$file" "$config_var" "${!var}"
            done

            # update OPTIONS:
            #   VpcCidrBlock SubnetCidrBlocks
            xsh log info "> updating OPTIONS: VpcCidrBlock SubnetCidrBlocks ..."
            x-util-sed-inplace "/CidrBlock/ s|<N>|$((stack))|g" "$file"
        )
    }

    function __update_node_config__ () {
        declare file=${1:?} stack=${2:?} mgr_stack_json=${3:?}

        xsh log info "updating node config file: $file ..."

        declare item output_key input_key value
        for item in "${XSH_AWS_CFN_VPN__CONFIG_OPTIONS_MAPPINGS_MGR_OUTPUT_TO_NODE_INPUT[@]}"; do
            output_key=${item%%:*}
            input_key=${item##*:}
            value="$(aws-cfn-stack-output-get "$mgr_stack_json" "$output_key")"
            xsh log info "> updating OPTIONS: $input_key ..."
            __replace_option_value_by_name__ "$file" "$input_key" "$value"
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

    function __set_to_prefix_if_prefix_is_empty__ () {
        #? Description:
        #?   Set the value of the variables with the prefix if the variables with the prefix are empty.
        #?
        #? Usage:
        #?   __set_to_prefix_if_prefix_is_empty__ PREFIX VAR1 VAR2 ...
        #?
        #? TODO:
        #?   - [ ] generalize the functiion to support the condition to be more flexible
        #?
        #?   function set-(from|to)-prefix () {
        #?       #? Usage:
        #?       #?   set-(from|to)-prefix PREFIX VAR [...]
        #?       #?
        #?       declare __prefix__=${1:?} __this_vars__=("${@:2}")
        #?   }
        #?   
        #?   function set-(from|to)-prefix-if () {
        #?       #? Usage:
        #?       #?   set-(from|to)-prefix-if CONDITION PREFIX VAR [...]
        #?       #?
        #?       #? Options:
        #?       #?   CONDITION     If the condition is met, then set the variables.
        #?       #?                 Syntax: (this|prefix)-is-[not-](set|empty|setempty)
        #?       #?   PREFIX        The prefix used to set from/to the variables.
        #?       #?   VAR           The name of the variables.
        #?       #?
        #?       #?
        #?       declare __condition__=${1:?} __prefix__=${2:?} __this_vars__=("${@:3}")
        #?   }
        #?
        declare __prefix__=${1:?}
        declare __this_vars__=("${@:2}")

        declare __prefix_var__ __this_var__
        for __this_var__ in "${__this_vars__[@]}"; do
            __prefix_var__=${__prefix__}${__this_var__}
            if [[ -z ${!__prefix_var__} ]]; then
                # shellcheck disable=SC2229
                read -r "${__prefix_var__}" <<< "${!__this_var__}"
            fi
        done
    }


    # main

    # set default values for global variables
    XACVC_BASE_DOMAIN=${XACVC_BASE_DOMAIN:-}
    XACVC_XACC_ENVIRONMENT=${XACVC_XACC_ENVIRONMENT:-sb}
    XACVC_XACC_RANDOM_STACK_NAME_SUFFIX=${XACVC_XACC_RANDOM_STACK_NAME_SUFFIX:-1}
    XACVC_XACC_OPTIONS_SSV2Ray=${XACVC_XACC_OPTIONS_SSV2Ray:-0}
    
    # set default values
    declare region \
            stacks=( 00 ) \
            profiles \
            base_name=vpn \
            dir \
            OPTIND OPTARG opt

    while getopts r:x:p:b:e:Rd:C: opt; do
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
                XACVC_XACC_ENVIRONMENT=$OPTARG
                ;;
            R)
                XACVC_XACC_RANDOM_STACK_NAME_SUFFIX=0
                ;;
            d)
                XACVC_BASE_DOMAIN=$(x-string-lower "$OPTARG")
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

    declare SSMAdminEmail SSMDomain L2TPDomain SSDomain

    # apply the derivation rules for domains and email address if base domain is set
    # shellcheck disable=SC2034
    if [[ -n ${XACVC_BASE_DOMAIN} ]]; then
        SSMAdminEmail=admin@${XACVC_BASE_DOMAIN}
        SSMDomain=admin.ss.${XACVC_BASE_DOMAIN}
        L2TPDomain=vpn.${XACVC_BASE_DOMAIN}

        if [[ $XACVC_XACC_OPTIONS_SSV2Ray -eq 1 ]]; then
            SSDomain=v2ray.ss.${XACVC_BASE_DOMAIN}
        else
            SSDomain=ss.${XACVC_BASE_DOMAIN}
        fi

        # apply the override values from the environment variables
        __set_to_prefix_if_prefix_is_empty__ XACVC_XACC_OPTIONS_ SSMAdminEmail SSMDomain L2TPDomain SSDomain
    fi

    # loop the list to generate config files
    declare stack index profile stack_name stack_region mgr_stack_json file
    for stack in "${stacks[@]}"; do
        index=$((stack))
        profile=${profiles[index]}
        stack_name=$base_name-$stack-$XACVC_XACC_ENVIRONMENT

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
            if [[ $XACVC_XACC_RANDOM_STACK_NAME_SUFFIX -eq 0 ]]; then
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

        # update the config file
        __update_config__ "$file" "$stack" "$base_name" "$stack_region"

        # update the node config file with the output of the manager stack
        if [[ $stack -gt 0 && -n $mgr_stack_json ]]; then
            __update_node_config__ "$file" "$stack" "$mgr_stack_json"
        fi
    done
}
