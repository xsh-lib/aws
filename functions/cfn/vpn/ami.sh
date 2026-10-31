# shellcheck disable=SC2148

#? Description:
#?   Get the latest AMIs for all enabled regions and build JSON in the format
#?   of Region-to-AMI mapping as the key `Mappings` in aws-cfn-vpn template.
#?   It takes a few minutes to finish, please be patient.
#?
#?   For each region the latest Amazon Linux 2023 AMI is fetched for BOTH the
#?   x86_64 architecture (emitted as keys `nameAmd64`/`AMIAmd64`) and, where
#?   published, the arm64 architecture (emitted as keys `nameArm64`/`AMIArm64`).
#?   The two architectures use symmetric, explicitly-labelled keys (Amd64 ==
#?   x86_64; Arm64 == aarch64). The arm64 keys let the aws-cfn-vpn template
#?   launch Graviton instance types (t4g.*, m6g.*, etc.) via its
#?   `Architecture=arm64` parameter.
#?
#?   All the AMIs are AWS free tier eligible and have the types:
#?     * ImageOwnerAlias: amazon
#?     * Public: true
#?     * State: available
#?     * Architecture: x86_64 and arm64
#?     * VirtualizationType: hvm
#?     * Description: Amazon Linux 2023 AMI*
#?
#?   Amazon Linux 2 reached end of support on 2026-06-30; this fetches the
#?   AL2023 successor AMIs (gp3-backed) of a pinned kernel flavor.
#?
#?   Some regions are not enabled for your account by default. Those regions
#?   will be updated with an empty AMI object: {}.
#?
#?   You can enable the disabled regions in your web console at:
#?   https://console.aws.amazon.com/billing/home?#/account
#?
#? Usage:
#?   @ami [-k KERNEL] [-r RELEASE] [-t TEMPLATE] [-C DIR]
#?
#? Options:
#?   [-k KERNEL]
#?
#?   The AL2023 kernel flavor, e.g. `6.1`, `6.12`, `6.18` or `default`.
#?   Default is `6.12`.
#?   `default` follows whatever AWS currently ships as the default kernel; it
#?   has moved before (6.1 -> 6.18), so regenerating with it is not
#?   reproducible.
#?
#?   [-r RELEASE]
#?
#?   Pin the AL2023 release, e.g. `2023.12.20261029.0`, instead of fetching
#?   the latest one. The AMIs are looked up by the name
#?   `al2023-ami-<RELEASE>-kernel-<KERNEL>-<ARCH>`, deprecated ones included,
#?   so KERNEL can't be `default` with this option.
#?   Pinning keeps the mapping in step with the AMI already deployed: any
#?   change of the mapped AMI replaces the EC2 instance on the next stack
#?   update.
#?
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
#?   # Get the latest kernel-6.12 AMIs for all enabled regions and update the stack.json.
#?   $ @ami -t stack.json
#?
#?   # Get the AMIs of a given release for all enabled regions.
#?   $ @ami -k 6.12 -r 2023.12.20261029.0
#?   "Mappings": {
#?     "RegionMap": {
#?         "ap-northeast-1": {
#?         "nameAmd64": "al2023-ami-2023.12.20261029.0-kernel-6.12-x86_64",
#?         "AMIAmd64": "ami-0d6ee5b06d13e7d94",
#?         "nameArm64": "al2023-ami-2023.12.20261029.0-kernel-6.12-arm64",
#?         "AMIArm64": "ami-0f73d81995003de5c",
#?         "created": "2026-10-29T18:10:08.000Z",
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
        #?   __get_ami_id__ <REGION> <ARCH> <KERNEL> [RELEASE]
        #?
        #? Options:
        #?   <ARCH>     CPU architecture: `x86_64` or `arm64`.
        #?   <KERNEL>   AL2023 kernel flavor, e.g. `6.12`.
        #?   [RELEASE]  AL2023 release, e.g. `2023.12.20261029.0`. The latest
        #?              release is used if omitted.
        #?
        declare region=${1:?} arch=${2:?} kernel=${3:?} release=$4
        if [[ -z $release ]]; then
            aws ssm get-parameters \
                --region "$region" \
                --names "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-${kernel}-${arch}" \
                --query 'Parameters[*].[Value]' \
                --output text
        else
            aws ec2 describe-images \
                --region "$region" \
                --owners amazon \
                --include-deprecated \
                --filters "Name=name,Values=al2023-ami-${release}-kernel-${kernel}-${arch}" \
                --query 'Images[*].[ImageId]' \
                --output text
        fi
    }

    function __get_ami__ () {
        #? Usage:
        #?   __get_ami__ <REGION> <KERNEL> [RELEASE]
        #?
        #? Emits a single JSON object per region carrying both the x86_64 AMI
        #? (keys `nameAmd64`/`AMIAmd64`) and, when available, the arm64 AMI
        #? (keys `nameArm64`/`AMIArm64`). The arm64 keys are omitted for regions
        #? that do not publish an arm64 Amazon Linux 2023 AMI, so the template's
        #? `Fn::FindInMap [.., AMIArm64]` only resolves where arm64 is supported.
        #?
        declare region=${1:?} kernel=${2:?} release=$3 \
                filters location id_x86 id_arm64 image_ids arm64_keys query
        filters=(
            "Name=is-public,Values=true"
            "Name=state,Values=available"
        )
        location=$(aws-region-long-name-get "$region")

        id_x86=$(__get_ami_id__ "$region" x86_64 "$kernel" "$release")
        if [[ -z $id_x86 ]]; then
            return
        fi

        image_ids=("$id_x86")
        arm64_keys=""
        id_arm64=$(__get_ami_id__ "$region" arm64 "$kernel" "$release")
        if [[ -n $id_arm64 ]]; then
            image_ids+=("$id_arm64")
            arm64_keys="nameArm64: Images[?Architecture=='arm64'] | [0].Name, AMIArm64: Images[?Architecture=='arm64'] | [0].ImageId, "
        fi

        query="{nameAmd64: Images[?Architecture=='x86_64'] | [0].Name, AMIAmd64: Images[?Architecture=='x86_64'] | [0].ImageId, ${arm64_keys}created: Images[?Architecture=='x86_64'] | [0].CreationDate, location: '${location}'}"

        aws ec2 describe-images \
            --region "$region" \
            --image-ids "${image_ids[@]}" \
            --query "$query" \
            --filter "${filters[@]}" \
            --output json
    }

    function __get_amis__ () {
        #? Usage:
        #?   __get_amis__ <KERNEL> [RELEASE]
        #?
        declare kernel=${1:?} release=$2 regions index ami
        # shellcheck disable=SC2207
        regions=( $(aws-region-list) )
        for index in "${!regions[@]}"; do
            printf "." >&2
            ami=$(__get_ami__ "${regions[index]}" "$kernel" "$release" | sed 's/  / /g')  # indent level: -1
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
    declare kernel=6.12 release template amis mappings \
            OPTIND OPTARG opt

    while getopts k:r:t: opt; do
        case $opt in
            k)
                kernel=${OPTARG:?}
                ;;
            r)
                release=${OPTARG:?}
                ;;
            t)
                template=$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -n $release && $kernel == default ]]; then
        xsh log error "-r RELEASE needs a concrete -k KERNEL, not 'default'."
        return 255
    fi

    amis=$(__get_amis__ "$kernel" "$release")
    # a mistyped KERNEL or RELEASE yields {} for every region; don't write that
    if [[ $amis != *'"AMIAmd64"'* ]]; then
        xsh log error "no AMI found in any region for kernel: $kernel${release:+, release: $release}"
        return 255
    fi
    mappings=$(__to_mappings__ "$amis")
    printf '%s\n' "$mappings"

    if [[ -n $template ]]; then
        __update_template__ \
            "$template" \
            "  ${mappings//$'\n'/$'\n'  },"  # indent level: +1, and append a comma

    fi
}
