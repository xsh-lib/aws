#? Description:
#?   Get CloudWatch metrics.
#?
#? Usage:
#?   @get
#?     -n <NAMESPACE>
#?     -m <METRIC_NAME> [...]
#?     [-s STATISTICS]
#?     [-d DIMENSION] [...]
#?     [-b BEGIN_TIME]
#?     [-e END_TIME]
#?     [-p PERIOD]
#?     [-r REGION]
#?     [-q QUERY]
#?     [-o json | text | table]
#?
#? Options:
#?   -n <NAMESPACE>
#?
#?   Namespace, without 'AWS/' prefix.
#?
#?   -m <METRIC_NAME> [...]
#?
#?   Metric name.
#?   Multiple -m is allowed.
#?
#?   [-s STATISTICS]
#?
#?   The metric statistics to return. Default is 'Average'.
#?
#?   [-d DIMENSION]
#?
#?   Dimension key value, format: Name=Value.
#?   Multiple -d is allowed.
#?
#?   [-b BEGIN_TIME]
#?
#?   The time stamp to use for determining the first datapoint to return in UTC.
#?
#?   [-e END_TIME]
#?
#?   The time stamp to use for determining the last datapoint to return in UTC.
#?   If both BEGIN_TIME and END_TIME is not given, curent timestamp will be
#?   used for END_TIME.
#?
#?   [-p PERIOD]
#?
#?   The granularity, in seconds, of the returned datapoints. period must
#?   be at least 60 seconds and must be a multiple of 60. Default is 3600.
#?
#?   [-r REGION]
#?
#?   Region name.
#?   Defalt is to use the region in your AWS CLI profile.
#?
#?   [-q QUERY]
#?
#?   A JMESPath query to use in filtering the response data.
#?   See spec of JMESPath: http://jmespath.org/specification.html
#?
#?   [-o json | text | table]
#?
#?   The formatting style for command output.
#?   The default is `json`.
#?
#? Example:
#?   # get the CPU average utilization in last 24 hours for EC2 instance i-xxxxxx.
#?   $ @get -n EC2 -m CPUUtilization -d InstanceId=i-xxxxxx -p 86400
#?   listing AWS/EC2 Average metric in 1440 minute(s) period between 2019-10-12 16:57:07 and 2019-10-13 16:57:07 (UTC).
#?
#?   InstanceId=i-xxxxxx:
#?
#?   CPUUtilization
#?   DATAPOINTS	0.192940347879	2019-10-12T16:57:00Z	Percent
#?
function get () {
    declare OPTIND OPTARG opt

    # set default
    declare stat='Average'
    declare period=3600 # 60 minutes

    declare namespace begin_time end_time
    declare -a metrics dimensions region_opt query output

    while getopts n:m:s:d:b:e:p:r:q:o: opt; do
        case $opt in
            n)
                namespace="AWS/$OPTARG"
                ;;
            m)
                metrics+=( "$OPTARG" )
                ;;
            s)
                stat=$OPTARG
                ;;
            d)
                dimensions+=( "$OPTARG" )
                ;;
            b)
                begin_time=$OPTARG
                ;;
            e)
                end_time=$OPTARG
                ;;
            p)
                period=${OPTARG:?}
                ;;
            r)
                region_opt=(--region "${OPTARG:?}")
                ;;
            q)
                # the selector `|[]` strips the outer layer of `[]` in the result
                # and if the result list is empty, won't give a literal null.
                query=(--query "$OPTARG")
                ;;
            o)
                output=(--output "$OPTARG")
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $namespace || ${#metrics[@]} -eq 0 ]]; then
        xsh log error "NAMESPACE and/or METRIC_NAME: parameters null or not set"
        return 255
    fi

    if [[ -z $begin_time && -z $end_time ]]; then
        end_time=$(TZ=UTC date '+%Y-%m-%d %H:%M:%S')
    fi

    if [[ -z $begin_time ]]; then
        begin_time=$(xsh /date/adjust -${period}S "${end_time:?}")
    elif [[ -z $end_time ]]; then
        end_time=$(xsh /date/adjust +${period}S "${begin_time:?}")
    else
        :
    fi

    printf "listing $namespace $stat metric in %s minute(s) period between %s and %s (UTC).\n" \
           "$(($period / 60))" "$begin_time" "$end_time"

    declare dimension_option metric
    for dimension in "${dimensions[@]:-empty}"; do
        if [[ $dimension != 'empty' ]]; then
            dimension_option="--dimensions Name=${dimension%%=*},Value=${dimension##*=}"
            printf "\n$dimension:\n\n"
        fi

        for metric in "${metrics[@]}"; do
            aws "${region_opt[@]}" "${query[@]}" "${output[@]}" \
                cloudwatch get-metric-statistics \
                --metric-name "${metric:?}" \
                --start-time "${begin_time:?}" \
                --end-time "${end_time:?}" \
                --period "$period" \
                --namespace "${namespace:?}" \
                --statistics "$stat" \
                $dimension_option
        done
    done
}
