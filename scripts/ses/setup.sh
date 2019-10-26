#!/bin/bash -e

#? Description:
#?   Setup AWS SES service step by step, trying to automate the procedure
#?   as much as possible.
#?
#? Usage:
#?   @setup -d DOMAIN [-r REGION] [-t EMAIL] [-u USER] [-f] [-m]
#?
#? Options:
#?   -d DOMAIN     Domain name for the SES service.
#?
#?   [-r REGION]   Setup SES in the given region.
#?                   * us-east-1
#?                   * us-west-2
#?                   * eu-west-1
#?                 Defalt is to use the region in your AWS CLI profile.
#?
#?   [-t EMAIL]    Send a test email after moving out of SES sandbox.
#?
#?   [-u USER]     Create an IAM user to access to SES SMTP service.
#?
#?   [-f]          Force delete the IAM user if already exists.
#?
#?   [-m]          Move the SES service out of the sandbox.
#?
#? Example:
#?   $ @setup -d yourdomain.com -u iam_username -m
#?
#? Reference:
#?   https://docs.aws.amazon.com/ses/latest/DeveloperGuide/quick-start.html
#?

VALID_REGIONS=(
    us-east-1
    us-west-2
    eu-west-1
)

while getopts d:r:t:u:fm opt; do
    case $opt in
        d)
            domain=$OPTARG
            ;;
        r)
            region=$OPTARG
            ;;
        t)
            email=$OPTARG
            ;;
        u)
            username=$OPTARG
            ;;
        f)
            force=1
            ;;
        m)
            move_out=1
            ;;
        *)
            exit 255
            ;;
    esac
done

if [[ -z $domain ]]; then
    xsh log error "DOMAIN: parameter null or not set"
    exit 255
fi

if [[ -z $region ]]; then
    region=$(aws configure get default.region)
fi

if printf '%s\n' "${VALID_REGIONS[@]}" | grep -q "$region"; then
    echo "setting up AWS SES service in the region: $region"
else
    xsh log error "AWS SES is not available in the region: $region, please use one of following regions: ${VALID_REGIONS[*]}"
    exit 255
fi

step=0

step=$((step + 1))
echo "$step. verifying domain identity."
xsh aws/ses/domain-identity -r "$region" "$domain"

step=$((step + 1))
echo "$step. verifying domain DKIM."
xsh aws/ses/domain-dkim -r "$region" "$domain"

if [[ -n $username ]]; then
    create_user=1

    step=$((step + 1))
    echo "$step. checking IAM user existence."
    if xsh aws/iam/user/exist "$username"; then
        if [[ $force -eq 1 ]]; then
            step=$((step + 1))
            echo "$step. deleting existing IAM user and all its belonging."
            xsh aws/iam/user/delete -f "$username"
        else
            xsh log warning "$username: user already exists."
            create_user=0
        fi
    fi

    if [[ $create_user -eq 1 ]]; then
        step=$((step + 1))
        echo "$step. creating IAM user."
        xsh aws/iam/user/create "$username"
    fi

    step=$((step + 1))
    echo "$step. attaching SES policy to IAM user."
    xsh aws/iam/user/policy/put \
        -u "$username" \
        -n AmazonSesSendingAccess \
        -d '{"Version": "2012-10-17", "Statement": [{ "Effect":"Allow", "Action":"ses:SendRawEmail", "Resource":"*"}]}'

    step=$((step + 1))
    echo "$step. checking access key existence."
    if xsh aws/iam/user/key/exist -u "$username"; then
        xsh log warning "$username: the user already has access key."
    else
        step=$((step + 1))
        echo "$step. creating access key for IAM user $username."
        out=$(xsh aws/iam/user/key/create -u "$username" \
                  -q '[AccessKey.AccessKeyId,AccessKey.SecretAccessKey]' \
                  -o text)
        if [[ -z $out ]]; then
            xsh log error "failed to create access key for $username."
            exit 255
        fi
        id=${out%%$'\t'*}
        secret=${out#*$'\t'}
    
        step=$((step + 1))
        echo "$step. sign the secret access key as SMTP credential."
        smtp_secret=$(xsh aws/iam/user/key/sign "$secret")
        if [[ -z $smtp_secret ]]; then
            xsh log error "failed to sign the secret access key: $secret."
            exit 255
        fi

        xsh log info "SMTP username: $id"
        xsh log info "SMTP password: $smtp_secret"
    fi
fi

if [[ $move_out -eq 1 ]]; then
    step=$((step + 1))
    echo "$step. moving out of SES sandbox."
    xsh aws/ses/sandbox/move -r "$region"
fi

if [[ -n $email ]]; then
    step=$((step + 1))
    echo "$step. sending test email through SES."
    xsh aws/ses/send -r "$region" -d "$domain" -t "$email"

    read -n 1 -s -r -p "press any key to continue"
    printf '\n\n'
fi

echo "AWS SES service setup completed."
echo
echo "to setup unix sendmail to use AWS SES SMTP service, use below commands:"
echo "for EC2 instance (Linux):"
echo "xsh aws/ses/ec2/setup -d $domain -r $region -u ${id:-SMTP_USERNAME} -p ${smtp_secret:-SMTP_PASSWORD} -m PLAIN -t ${email:-YOUR_EMAIL_ADDREESS}"
echo
echo "for macOS:"
echo "xsh aws/ses/macos/setup -d $domain -r $region -u ${id:-SMTP_USERNAME} -p ${smtp_secret:-SMTP_PASSWORD} -t ${email:-YOUR_EMAIL_ADDREESS}"

exit
