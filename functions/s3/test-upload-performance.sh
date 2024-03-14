#? Description:
#?   Test performance for uploading to S3.
#?
#? Usage:
#?   @test-upload-performance [DIR]
#?
#? Options:
#?   [DIR]
#?
#?   Directories to be uploaded, regex is allowed.
#?   If no dir specified, will upload all directories under current path.
#?
#? Example:
#?   $ declare -a fsize=(32k 4M 128M) fnum=(4096 32 1)
#?   $ declare index num
#?   $ for index in ${!fsize[@]}; do mkdir -p size-${fsize[index]}; for num in $(seq 1 ${fnum[index]}); do dd bs=${fs[index]} if=/dev/random of=size-${fsize[index]}/$num count=1 1>/dev/null 2>&1; done; done
#?   $ @test-upload-performance 'size-*'
#?   make_bucket: aws-s3-test-upload-performance-28772
#?   > Uploading size-128M (1 file(s), 128M) ... 31.449 seconds
#?   > Uploading size-32k (4096 file(s), 128M) ... 115.233 seconds
#?   > Uploading size-4M (32 file(s), 128M) ... 30.618 seconds
#?   Done
#?   remove_bucket: aws-s3-test-upload-performance-28772
#?
#? @xsh import /trap/return
#? @xsh /trap/err -rE
#? @subshell
#?
function test-upload-performance () {
    declare regex=$1 depth=0

    if [[ -z $regex ]]; then
        regex=.
        depth=1
    fi

    declare tmp_s3_bucket="s3://aws-s3-test-upload-performance-$RANDOM"
    aws s3 mb "$tmp_s3_bucket"
    x-trap-return -f "${FUNCNAME[0]}" "aws s3 rb --force $tmp_s3_bucket | tail -1"

    # set output format for bash keyword 'time' to get the real time
    declare TIMEFORMAT=%R

    declare dir count size duration
    # shellcheck disable=SC2086
    while read -r dir; do
        count=$(find "$dir" -type f -exec printf x \; | wc -c | tr -d ' ')
        size=$(du -sh "$dir" | awk '{print $1}')

        printf '> Uploading %s (%s file(s), %s) ... ' "$dir" "$count" "$size"

        # using bash keyword 'time' rather than 'time' command
        duration=$( { time aws s3 cp "$dir" "$tmp_s3_bucket" --recursive --only-show-errors; } 2>&1 )

        printf '%s seconds\n' "$duration"
    done < <(find $regex -depth "$depth" | sort)

    say -i "Done"
}
