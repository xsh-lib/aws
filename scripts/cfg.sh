#!/bin/bash -e

#? Usage:
#?     @cfg -l
#?     @cfg -a PROFILE
#?     @cfg -c TARGET_PROFILE [-s SOURCE_PROFILE] [-r REGION]
#?
#? Options:
#?     -l
#?
#?     List all profiles.
#?
#?     -a PROFILE
#?
#?     Set the profile as default.
#?
#?     -c TARGET_PROFILE
#?
#?     Copy source profile to target profile.
#?     If target profile already exists, will be overrided.
#?
#?     [-s SOURCE_PROFILE]
#?
#?     Use with -c, specify source profile name, default to use current profile.
#?
#?     [-r REGION]
#?
#?     Use with -c, specify a new region name.
#?

CONF_DIR=~/.aws
CONF_FILE=${CONF_DIR}/config
CREDENTIAL_FILE=${CONF_DIR}/credentials
BAK_SUFFIX=$(date '+%Y%m%d-%H%M%S')
BAK_CONF_FILE=${CONF_FILE}.bak.${BAK_SUFFIX}
BAK_CREDENTIAL_FILE=${CREDENTIAL_FILE}.bak.${BAK_SUFFIX}


function get_profile () {
    local profile
    local region aws_access_key_id aws_secret_access_key output

    profile=${1:-default}

    if [[ $profile != 'default' ]]; then
        profile="profile.$profile"
    fi

    region=$(aws configure get $profile.region)
    aws_access_key_id=$(aws configure get $profile.aws_access_key_id)
    aws_secret_access_key=$(aws configure get $profile.aws_secret_access_key)
    output=$(aws configure get $profile.output)

    printf "%s %s %s %s\n" "$region" "$aws_access_key_id" "$aws_secret_access_key" "$output"
}

function set_profile () {
    local profile
    local region aws_access_key_id aws_secret_access_key output

    profile=${1:-default}
    region=$2
    aws_access_key_id=$3
    aws_secret_access_key=$4
    output=$5

    if [[ $profile != 'default' ]]; then
        profile="profile.$profile"
    fi

    bak_profile
    aws configure set $profile.region "$region"
    aws configure set $profile.aws_access_key_id "$aws_access_key_id"
    aws configure set $profile.aws_secret_access_key "$aws_secret_access_key"
    aws configure set $profile.output "$output"
    clean
}

function get_profiles () {
    local profiles

    profiles=( $(awk '/\[(profile )*.+]/ {print $NF}' "${CONF_FILE}" | tr -d '[]') )
    local p
    for p in "${profiles[@]}"; do
        printf "$p "
        get_profile "$p"
    done
}

function highlight_line () {
    local HB='\033[1m'
    local HE='\033[0m'

    if [[ -n $1 ]]; then
        cat | awk -v pattern="$1" -v HB=$HB -v HE=$HE '{if(match($0, pattern) > 0) print HB $0 HE; else print}'
    else
        cat
    fi
}

function get_default_equals () {
    local pattern
    pattern="$(echo "$1" | awk '$1 == "default" {print ".+", $2, $3, ".+", $5}')"
    echo "$1" | egrep "$pattern" | awk '{print $1}'
}

function mask () {
    cat | awk -v field=$1 -v start=$2 -v end=$3 '{$field="******" substr($field, start, end); print}'
}

function list_profiles () {
    local profiles default_equels pattern

    printf "listing profiles...\n\n"

    profiles="$(get_profiles)"
    default_equels=( $(get_default_equals "$profiles") )
    pattern="$(echo "${default_equels[@]}" | sed 's/ /|/g')"
    if [[ -n $pattern ]]; then
        pattern="($pattern)"
    else
        :
    fi

    {
        printf "%s %s %s %s %s\n" 'profile' 'region' 'access_key' 'secret_key' 'output'
        printf "%s %s %s %s %s\n" '-------' '------' '----------' '----------' '------'
        printf "$profiles\n" | mask 4 36 4
    } \
        | column -t \
        | highlight_line "$pattern"
}

function bak_profile () {
    /bin/cp -a "${CONF_FILE}" "${BAK_CONF_FILE}"
    /bin/cp -a "${CREDENTIAL_FILE}" "${BAK_CREDENTIAL_FILE}"
}

function clean ()
{
    /bin/rm -f "${BAK_CONF_FILE}" "${BAK_CREDENTIAL_FILE}"
}

function activate_profile () {
    local profile=$1

    if [[ $profile == 'default' ]]; then
        printf "default profile doesn't need to activate.\n"
        return 255
    else
        :
    fi

    printf "activating profile: $profile\n"
    set_profile 'default' $(get_profile "$profile")
}

function copy_profile () {
    local source target region

    source=$1
    target=$2
    region=$3

    if [[ $target == 'default' ]]; then
        printf "default profile can't be target.\n"
        return 255
    else
        :
    fi

    printf "copying profile from: ${source:-default} to: $target\n"
    set_profile "$target" $(get_profile "$source")

    if [[ -n $region ]]; then
        printf "updating $target region to: $region\n"
        aws configure set profile.$target.region $region
    fi
}


# MAIN

while getopts la:c:s:r:h opt; do
    case $opt in
        l)
            action='list'
            ;;
        a)
            action='activate'
            profile=$OPTARG
            ;;
        c)
            action='copy'
            profile=$OPTARG
            ;;
        s)
            source_profile=$OPTARG
            ;;
        r)
            region=$OPTARG
            ;;
        *)
            exit 255
            ;;
    esac
done

if [[ -z $action ]]; then
    exit 255
fi

# check profile
if [[ ! -s ${CONF_FILE} ]]; then
    echo "ERROR: No configuration file found at '${CONF_FILE}'! Please run 'aws configure [--profile <NAME>]' first." 1>&2
    exit 255
fi

if [[ $action == 'list' ]]; then
    list_profiles
elif [[ $action == 'activate' ]]; then
    activate_profile "$profile"
    list_profiles
elif [[ $action == 'copy' ]]; then
    copy_profile "$source_profile" "$profile" "$region"
    list_profiles
fi

exit
