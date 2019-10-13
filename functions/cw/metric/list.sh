#? Description:
#?   List all available Namespaces, Metrics and Dimensions for current user.
#?
#? Usage:
#?   @list
#?
function list () {

    function __get_metrics__ () {
        cat | awk '/^METRICS/ {
                  split($3, a, "/");
                  print a[2], $2;
              }' \
            | sort -u
    }

    function __get_dimensions__ () {
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

    function __format_output__ () {
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
                     printf "\n  " $0 "\n\n";
                  } else {
                     printf "    " $0 "\n";
                  }
              }'
    }


    local out="$(aws cloudwatch list-metrics --output text)"

    echo "Namespace and Metrics:"
    echo "$out" | __get_metrics__ | __format_output__ 3
    echo
    echo "Namespace and Dimentions:"
    echo "$out" | __get_dimensions__ | __format_output__ 2
}
