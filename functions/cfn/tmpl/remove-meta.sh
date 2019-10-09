#? Description:
#?   Remove Meta node for CloudFormation Desgin form template.
#?
#? Usage:
#?   @remove-meta <cloudformation-template.json>
#?
function remove-meta () {

    function __remove_meta__ () {
        # 1. Remove Meta node for CloudFormation Desgin form template
        # 2. remove ilegal comma ',' from JSON
        cat "$1" | sed '/^  "Metadata"/,$d' | sed '/"Metadata"/{N;N;N;N;d;}' | cat - <(echo \}) \
            | awk '{if (last_ln) {if (match($0, "^[ ]*[\]}]")>0) {sub(",$","",last_ln); print last_ln} else {print last_ln}}; last_ln=$0} END {print last_ln}'
        return $((PIPESTATUS+$?))
    }

    if [[ $# -le 0 && ! -s /dev/stdin ]]; then
        usage
    fi

    __remove_meta__ "${1:--}"
}
