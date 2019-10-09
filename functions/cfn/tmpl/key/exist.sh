#? Description:
#?   Check EC2 key pair existence that is referred by the template.
#?   The template should be a well formatted JSON file and has at least a key in name
#?   `Resources`.
#?
#? Usage:
#?   @exist <TEMPLATE>
#?
#? Example:
#?   $ @exist /dev/stdin <<< '{"Resources": {"myinstance": {"Properties": {"KeyName": "foo"}}}}'
#?   Checking key pair existence: foo... [Not Found]
#?
function exist () {
    local template=${1:?}

    local names
    names=$(
        xsh /json/parser eval "$(cat "$template")" \
            '[val["Properties"]["KeyName"] for val in {JSON}["Resources"].values() \
                 if val.has_key("Properties") \
                 and val["Properties"].has_key("KeyName") \
                 and isinstance(val["Properties"]["KeyName"], (str, unicode))]' \
            | tr -d '[]" ' \
            | sed 's/,/ /g')
    
    local ret=0 name

    for name in $names; do
        printf "Checking key pair existence: $name..."
        if xsh aws/ec2/key/exist "$name"; then
            printf " [OK]\n"
        else
            printf " [Not Found]\n"
            ret=$((ret + 1))
        fi
    done

    return $ret
}
