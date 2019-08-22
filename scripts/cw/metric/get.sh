#!/bin/bash -e

#? Description:
#?   Get CloudWatch metrics.
#?
#? Usage:
#?   @get
#?     -n <NAMESPACE>
#?     -m <METRIC_NAME> [...]
#?     [-s STATISTICS]
#?     [-d DIMENSION] [...]
#?     [-b START_TIME]
#?     [-e END_TIME]
#?     [-p PERIOD]
#?     [-l]
#?
#? Options:
#?
#?   -n <NAMESPACE>
#?
#?   Namespace, without 'AWS/' prefix.
#?
#?   -m <METRIC_NAME> [...]
#?
#?   Metric name. Multi -m is allowed.
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
#?   [-b START_TIME]
#?
#?   The time stamp to use for determining the first datapoint to return in UTC.
#?
#?   [-e END_TIME]
#?
#?   The time stamp to use for determining the last datapoint to return in UTC.
#?   If both START_TIME and END_TIME is not given, curent timestamp will be
#?   used for END_TIME.
#?
#?   [-p PERIOD]
#?
#?   The granularity, in seconds, of the returned datapoints. period must
#?   be at least 60 seconds and must be a multiple of 60. Default is 3600.
#?
#?   [-l]
#?
#?   List all available Namespace, Metrics and Dimensions for current user.
#?

# TODO:
. "$BASE_DIR/xdt.sh"

function list_metrics () {
    local out="$(aws cloudwatch list-metrics --output text)"

    echo "Namespace and Metrics:"
    echo "$out" | get_metrics | format_output 3
    echo
    echo "Namesapce and Dimentions:"
    echo "$out" | get_dimensions | format_output 2
}

function get_metrics () {
    cat | awk '/^METRICS/ {
              split($3, a, "/");
              print a[2], $2;
          }' \
        | sort -u
}

function get_dimensions () {
    cat | awk '{
              if ($1 == "METRICS") {
                 split($3, a, "/");
              };
              if ($1 == "DIMENSIONS") {
                 print a[2] "\t" $2 "=" $3
              };
          }' \
        | sort -u
}

function format_output () {
    local columns=${1:-1}

    cat | awk -v column="$columns" '{
              if (last != $1) {
                 printf "\n" $1 ":\n";
                 i=1;
              };
              if (i > column) {
                 printf "\n";
                 i=1;
              };
              printf "\t" $2;
              i++;
              last=$1;
          }
          END {printf "\n"}' \
        | column -t \
        | awk '{
              if (match($0, ".+:$") > 0) {
                 printf "\n\t" $0 "\n\n";
              } else {
                 printf "\t" $0 "\n";
              }
          }'
}

function get () {
    local OPTIND OPTARG opt

    # set default
    local stat='Average'
    local period=3600 # 60 minutes

    local namespace start_time end_time
    declare -a metrics dimensions

    while getopts n:m:s:d:b:e:p:l opt; do
        case $opt in
            n)
                namespace="AWS/$OPTARG"
                ;;
            m)
                metrics[${#metrics[@]}]=$OPTARG
                ;;
            s)
                stat=$OPTARG
                ;;
            d)
                dimensions[${#dimensions[@]}]=$OPTARG
                ;;
            b)
                start_time=$OPTARG
                ;;
            e)
                end_time=$OPTARG
                ;;
            p)
                period=$OPTARG
                ;;
            l)
                list_metrics
                return
                ;;
            *)
                return 255
                ;;
        esac
    done

    if [[ -z $start_time && -z $end_time ]]; then
        end_time="$(TZ=UTC date '+%Y-%m-%d %H:%M:%S')"
    fi

    if [[ -z $start_time ]]; then
        start_time="$(xdt.adjust -${period}S "${end_time:?}")"
    elif [[ -z $end_time ]]; then
        end_time="$(xdt.adjust +${period}S "${start_time:?}")"
    else
        :
    fi

    printf "listing $namespace $stat metric in %s minute(s) period between %s and %s (UTC).\n" "$(($period / 60))" "$start_time" "$end_time"

    local dimension_option metric
    for dimension in "${dimensions[@]:-empty}"; do
        if [[ $dimension != 'empty' ]]; then
            dimension_option="--dimensions Name=${dimension%%=*},Value=${dimension##*=}"
            printf "\n$dimension:\n\n"
        fi

        for metric in "${metrics[@]}"; do
            aws cloudwatch get-metric-statistics \
                --metric-name "${metric:?}" \
                --start-time "${start_time:?}" \
                --end-time "${end_time:?}" \
                --period "$period" \
                --namespace "${namespace:?}" \
                --statistics "$stat" \
                $dimension_option \
                --output text \
                | sort -k3
        done
    done
}

get "$@"

exit
