#? Description:
#?   List available namespaces, metrics and dimensions in CloudWatch.
#?
#? Usage:
#?   @list [-r REGION]
#?
#? Options:
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#? Example:
#?   $ @list
#?   NAMESPACE [METRICS] DIMENSIONS ...
#?   --------- --------- ---------- ---
#?   AWS/Usage [CallCount] Type=API Resource=GetMetricStatistics Service=CloudWatch Class=None
#?
function list () {
    declare OPTIND OPTARG opt
    declare -a region_opt

    while getopts r: opt; do
        case $opt in
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            *)
                return 255
                ;;
        esac
    done

    printf "%s\n" "NAMESPACE [METRICS] DIMENSIONS ..."
    printf "%s\n" "--------- --------- --------------"

    aws "${region_opt[@]}" \
        --query "Metrics[*][join(' ', \
                                 [Namespace, \
                                  join('', ['[', MetricName, ']']), \
                                  join(' ', map(&join('=', [Name, Value]), Dimensions))])]" \
        --output text \
        cloudwatch list-metrics \
        | sort
}
