#!/bin/bash -e

#? Description:
#?   Extract EC2 instances Name and IP to local store.
#?   Run this util under root or `sudo -E` if specifying hosts store.
#?
#? Usage:
#?   @extract
#?     [-r REGION]
#?     [-i]
#?     STORE
#?
#? Options:
#?   [-r REGION]   Operating in the given region.
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   [-i]          Extract private IP rather than public IP.
#?
#?   STORE         Extract Name and IPs in to the store:
#?                   * hosts: /etc/hosts
#?                   * ssh: ~/.ssh/config
#?
#? Example:
#?   $ @extract ssh
#?   $ sudo -E @extract hosts
#?   $ sudo -u someuser_can_write_hosts -E @extract
#?
#? Developer:
#?   This util can not be implemented as functions because functions
#?   won't be available after `sudo -E`.
#?
function extract () {
    local OPTIND OPTARG opt

    local region ip_attr=PublicIpAddress store
    while getopts r:i opt; do
        case $opt in
            r)
                region=$OPTARG
                ;;
            i)
                ip_attr=PrivateIpAddress
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    store=${1:?}

    # const
    local -a hosts_conf=/etc/hosts
    local -a hosts_tmpl="%s %s\n"
    local -a hosts_query="Instances[?not_null(Tags[?Key=='Name'].Value|[0])!=''][$ip_attr,Tags[?Key=='Name'].Value|[0]]"

    local -a ssh_conf=~/.ssh/config
    local -a ssh_tmpl="Host %s\n    HostName %s\n    User ec2-user\n    IdentityFile ~/.ssh/%s\n    Port 22\n"
    local -a ssh_query="Instances[?not_null(Tags[?Key=='Name'].Value|[0])!=''][KeyName,$ip_attr,Tags[?Key=='Name'].Value|[0]]"

    local name
    # dynamic set variables
    for name in conf tmpl query; do
        local $name=${store}_$name
    done

    if [[ ! -w "${!conf}" ]]; then
        xsh log error "${!conf}: the file is not writable by $(id -un)"
        exit 255
    fi

    local -a ips
    # list unterminated instances
    # filter out the instances without a tag `Name` or without a value for tag `Name`
    # the `[]` around the tag is stripped
    # outputs at each line: [KeyName]    (Public|Private)IpAddress    Tags['Name']
    ips=( $(xsh aws/ec2/desc -f instance-state-name=pending,running,stopping,stopped \
              -f "tag:Name=*" \
              -q "${!query}" \
              -o text) )

    local count
    case $store in
        hosts)
            # count number of EC2 instance
            count=$((${#ips[@]} / 2))
            :
            ;;
        ssh)
            # count number of EC2 instance
            count=$((${#ips[@]} / 3))
            # revert the order of columns
            ips=( $(awk '{for (i=NF; i>0; i--) printf $i (i>1?OFS:RS)}' <<< "${ips[@]}") )
            ;;
        *)
            xsh log error "$store: unsupported store."
            return 255
            ;;
    esac

    local entries
    if [[ $count -gt 0 ]]; then
        local full_tmpl
        # generate full template according to the number of EC2 instance
        full_tmpl=$(xsh /string/repeat/3 "${!tmpl}" "$count")

        # generate entries
        entries=$(printf "$full_tmpl" "${ips[@]}")
    else
        return
    fi

    local access_key
    access_key=$(aws configure get default.aws_access_key_id)

    if [[ -z $region ]]; then
        region=$(aws configure get default.region)
    fi

    local s1 s2
    s1="## ---- BEGIN OF - ${access_key} - ${region} ----"
    s2="## ------ END OF - ${access_key} - ${region} ----"

    printf "%s" "$entries"
    # insert the entries at the end of file
    # remove existing entries if exists
    xsh /file/inject -c "$entries" \
        -p end \
        -m "$s1" \
        -n "$s2" \
        -x "$s1" \
        -y "$s2" \
        "${!conf}"
}

extract "$@"

exit
