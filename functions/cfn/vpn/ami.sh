# shellcheck disable=SC2148

#? Description:
#?   Get the latest AMIs for all enabled regions and build JSON in the format
#?   of Region-to-AMI mapping as the key `Mappings` in aws-cfn-vpn template.
#?   It takes a few minutes to finish, please be patient.
#?
#?   All the AMIs are AWS free tier eligible and have the types:
#?     * ImageOwnerAlias: amazon
#?     * Public: true
#?     * State: available
#?     * Architecture: x86_64
#?     * Hypervisor: xen
#?     * VirtualizationType: hvm
#?     * Description: Amazon Linux 2 AMI*
#?
#?   Some regions are not enabled for your account by default. Those regions
#?   will be updated with an empty AMI object: {}.
#?
#?   You can enable the disabled regions in your web console at:
#?   https://console.aws.amazon.com/billing/home?#/account
#?
#? Usage:
#?   @ami [-t TEMPLATE] [-C DIR]
#?
#? Options:
#?   [-t TEMPLATE]
#?
#?   Update the TEMPLATE file with the new mapping on the key `Mappings`.
#?   The file must be in JSON format and be at local.
#?
#?   [-C DIR]
#?
#?   Change the current directory to DIR before doing anything.
#?
#? Example:
#?   # Get the latest AMIs for all enabled regions and update the stack.json.
#?   $ @ami -t stack.json
#?   "Mappings": {
#?     "RegionMap": {
#?         "ap-northeast-1": {
#?         "name": "amzn2-ami-hvm-2.0.20240131.0-x86_64-gp2",
#?         "AMI": "ami-02636d39193812441",
#?         "created": "2024-01-26T19:11:44.000Z",
#?         "location": "Asia Pacific (Tokyo)"
#?         },
#?         ...
#?     }
#?   }
#?
#? @xsh /trap/err -eE
#? @subshell
#?
#? @xsh imports /file/inject
#? @xsh imports aws/region/list aws/region/long-name/get
#?
function ami () {
    
    function __get_ami_id__ () {
        #? Usage:
        #?   __get_ami_id__ <REGION>
        #?
        declare region=${1:?}
        aws ssm get-parameters \
            --region "$region" \
            --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
            --query 'Parameters[*].[Value]' \
            --output text
    }

    function __get_ami__ () {
        #? Usage:
        #?   __get_ami__ <REGION>
        #?
        declare region=${1:?} filters location id
        filters=(
            "Name=is-public,Values=true"
            "Name=state,Values=available"
        )
        location=$(aws-region-long-name-get "$region")
        id=$(__get_ami_id__ "$region")
        if [[ -z $id ]]; then
            return
        fi
        aws ec2 describe-images \
            --region "$region" \
            --image-ids "$id" \
            --query 'Images[0].{name:Name,AMI:ImageId,created:CreationDate,location:'"'$location'"'}' \
            --filter "${filters[@]}" \
            --output json
    }

    function __get_amis__ () {
        #? Usage:
        #?   __get_amis__
        #?
        declare regions index ami
        # shellcheck disable=SC2207
        regions=( $(aws-region-list) )
        for index in "${!regions[@]}"; do
            printf "." >&2
            ami=$(__get_ami__ "${regions[index]}" | sed 's/  / /g')  # indent level: -1
            printf '"%s": %s' "${regions[index]}" "${ami:-{\}}"  # ami: None ==> {}
            if [[ $index -lt $((${#regions[@]} - 1)) ]]; then
                printf ",\n"
            else
                printf "\n"
            fi
        done
        printf "\n" >&2
    }

    function __to_mappings__ () {
        #? Usage:
        #?   __to_mappings__ <AMIS_JSON>
        #?
        declare amis=${1:?}
        printf '"Mappings": {\n  "RegionMap": {\n%s\n  }\n}\n' \
            "    ${amis//$'\n'/$'\n'    }"  # indent level: +2
    }

    function __update_template__ () {
        #? Usage:
        #?   __update_template__ <FILE> <MAPPINGS>
        #?
        declare file=${1:?} mappings=${2:?}
        printf 'updating mappings in: %s ...' "$file"
        x-file-inject \
            -c "$mappings" \
            -p before \
            -e '^  "Outputs": \{$' \
            -x '^  "Mappings": \{$' \
            -y '^  \},$' \
            "$file"
        printf " [done]\n"
    }


    # main
    declare template amis mappings \
            OPTIND OPTARG opt

    while getopts t: opt; do
        case $opt in
            t)
                template=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    amis=$(__get_amis__)
    mappings=$(__to_mappings__ "$amis")
    printf '%s\n' "$mappings"

    if [[ -n $template ]]; then
        __update_template__ \
            "$template" \
            "  ${mappings//$'\n'/$'\n'  },"  # indent level: +1, and append a comma

    fi
}
