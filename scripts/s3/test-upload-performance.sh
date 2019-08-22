#!/bin/bash -e

#? Description:
#?   Test performance for uploading to S3.
#?
#? Usage:
#?   @test-upload-performance [DIR]
#?
#? Options:
#?   [DIR]    Directory to be uploaded, regex is allowed.
#?            If no dir specified, will upload all directories under current path.
#?
function test--upload-performance () {
    local dirs=(
        $(find . -depth 1 -type d -name "$1" \
              | sort -n)
    )

    local tmp_s3_bucket="s3://test-upload-$RANDOM"
    aws s3 mb "$tmp_s3_bucket"

    local dir count size
    for dir in "${dirs[@]}"; do
        count=$(ls -1 "$dir" | wc -l | tr -d ' ')
        size=$(du -sh "$dir" | awk '{print $1}')

        printf ">>Uploading $dir ($count files, $size) to AWS S3:"
        time aws s3 cp "$dir" $tmp_s3_bucket --recursive --only-show-errors 1>/dev/null 2>&1

        if [[ $? -eq 0 ]]; then
            printf ">>SUCCEEDED\n\n"
        else
            printf ">>FAILED!!\n\n"
        fi
    done

    aws s3 rb --force $tmp_s3_bucket | tail -1

    say -i ">>Done"
}

exit
