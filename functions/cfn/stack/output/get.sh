#? Dscription:
#?   Get stack output value by key.
#?
#? Usage:
#?   @get OUTPUT_JSON KEY
#?
#? Options:
#?   OUTPUT_JSON
#?
#?   Output JSON string.
#?
#?   KEY
#?
#?   Output key.
#?
function get () {
    declare json=${1:?} key=${2:?}
    xsh /json/parser eval "$json" "[item['OutputValue'] for item in {JSON}['Stacks'][0]['Outputs'] if item['OutputKey'] == '""$key""'][0]"
}
