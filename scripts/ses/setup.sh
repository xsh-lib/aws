#!/bin/bash

#? Description:
#?   Setup AWS SES service step by step, trying to automate the procedure
#?   as much as possible.
#?
#? Usage:
#?   @setup -d DOMAIN [-t EMAIL] [-u USERNAME]
#?

VALID_REGIONS=(
    us-east-1
    us-west-2
    eu-west-1
)

while getopts d:t:u:h opt; do
    case $opt in
        d)
            domain=$OPTARG
            ;;
        t)
            email=$OPTARG
            ;;
        u)
            username=$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

if [[ -z $domain ]]; then
    xsh log error "DOMAIN: parameter null or not set"
    exit 255
fi

region=$(aws configure get default.region)
if ! printf '%s\n' "${VALID_REGIONS[@]}" | grep -q "$region"; then
    xsh log error "AWS SES is not available in the region: $region, please use one of following regions: ${VALID_REGIONS[*]}"
    exit 255
fi

printf "STEP 1: Verifying domain identity.\n\n"

aws ses verify-domain-identity --domain "$domain" >/dev/null
iva_out=$(aws ses get-identity-verification-attributes --identities "$domain")
iva_status=$(xsh /json/parser eval "$iva_out" '{JSON}["VerificationAttributes"]["'$domain'"]["VerificationStatus"]')

if [[ $iva_status != Success ]]; then
    iva_txt_value=$(xsh /json/parser eval "$iva_out" '{JSON}["VerificationAttributes"]["'$domain'"]["VerificationToken"]')
    echo "Add below record to the domain $domain:"
    echo "Record Type: TXT (Text)"
    echo "TXT Name*: _amazonses.$domain"
    echo "TXT Value: $iva_txt_value"
    echo ""
else
    printf "Domain $domain is already verified.\n\n"
fi

aws ses verify-domain-dkim --domain "$domain" >/dev/null
idva_out=$(aws ses get-identity-dkim-attributes --identities "$domain")
idva_status=$(xsh /json/parser eval "$idva_out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimVerificationStatus"]')

if [[ $idva_status != Success ]]; then
    idva_values[0]=$(xsh /json/parser eval "$idva_out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimTokens"][0]')
    idva_values[1]=$(xsh /json/parser eval "$idva_out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimTokens"][1]')
    idva_values[2]=$(xsh /json/parser eval "$idva_out" '{JSON}["DkimAttributes"]["'$domain'"]["DkimTokens"][2]')
    echo "Add below records to the domain $domain:"
    for v in "${idva_values[@]}"; do
        echo "Record Type: CNAME"
        echo "Name: $v._domainkey.$domain"
        echo "Value: $v.dkim.amazonses.com"
        echo ""
    done
else
    printf "Domain $domain DKIM is already verified.\n\n"
fi

printf "STEP 2: Move out of SES sandbox.\n\n"

echo "Go to below URL to create a support case to move your account out of Amazon SES sandbox:"
echo "https://aws.amazon.com/ses/extendedaccessrequest/"
echo "Here's the help document about how to create this case:"
echo "http://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html"
echo "If your account is still in the Amazon SES sandbox, you may only send to verified addresses or domains, or to email addresses associated with the Amazon SES Mailbox Simulator."
echo ""
read -n 1 -s -r -p "Press any key to continue"
echo ""
echo ""

printf "STEP 3: Send a test email through SES.\n\n"

if [[ -n $email ]]; then
    if [[ $iva_status != Success ]]; then
        echo "Before you are able to send email, domain $domain must be verified."
        echo "Waiting for AWS SES to verify domain $domain, it may take hours."
        echo "So have a coffee now, once verified, will continue."
        ret=255
        while [[ $ret != 0 ]]; do
            printf "."
            aws ses wait identity-exists --identities "$domain" >/dev/null
            ret=$?
        done

        printf "\nDomain $domain has been verified by AWS SES.\n\n"
    fi

    aws ses send-email \
        --from "no-reply@$domain" \
        --to "$email" \
        --subject "${0##*/} test Email" \
        --text "This is a test Email sent through AWS SES." >/dev/null
    echo "A test email has been sent to $email, please check the inbox."
    read -n 1 -s -r -p "Press any key to continue"
    echo ""
    echo ""
else
    printf "skipped\n\n"
fi

printf "STEP 4: Create SMTP credential.\n\n"

if [[ -n $username ]]; then
    aws iam get-user --user-name "$username" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "Creating user $username."
        aws iam create-user --user-name "$username" >/dev/null
    else
        echo "User "$username" already exists."
    fi

    echo "Set SES policy for user $username."
    aws iam put-user-policy \
        --user-name "$username" \
        --policy-name AmazonSesSendingAccess \
        --policy-document '{"Version": "2012-10-17", "Statement": [{ "Effect":"Allow", "Action":"ses:SendRawEmail", "Resource":"*"}]}'

    keys=$(aws iam list-access-keys --user-name "$username")
    found_key=$(xsh /json/parser eval "$keys" 'len({JSON}["AccessKeyMetadata"])')
    if [[ $found_key -eq 0 ]]; then
        echo "Creating access key for user $username."
        key=$(aws iam create-access-key --user-name "$username")
        access_key_id=$(xsh /json/parser get "$key" AccessKey.AccessKeyId)
        secret_access_key=$(xsh /json/parser get "$key" AccessKey.SecretAccessKey)

        message="SendRawEmail"
        version_in_bytes='\x02';
        signature_in_bytes=$(echo -n "$message" | openssl dgst -sha256 -hmac "$secret_access_key" -binary)
        smtp_secret_access_key=$(echo -e -n "${version_in_bytes}${signature_in_bytes}" | base64)

        echo "SMTP username: $access_key_id"
        echo "SMTP password: $smtp_secret_access_key"
    else
        echo "Access key for user $username already exists."
    fi

    echo ""
else
    printf "skipped\n\n"
fi

printf "STEP 5: AWS SES service setup completed.\n\n"

printf "STEP 6: Setup sendmail to use AWS SES SMTP server.\n\n"

printf "STEP 6.1: On EC2 instance\n\n"
echo "Execute below command on EC2 instance:"
echo "git clone https://github.com/alexzhangs/aws-ec2-ses"
echo "sh aws-ec2-ses/install.sh"
echo "aws-ec2-ses-setup.sh -d $domain -r $region -u ${access_key_id:SMTP_USERNAME} -p ${smtp_secret_access_key:SMTP_PASSWORD} -m PLAIN -t ${email:YOUR_EMAIL_ADDREESS}"
echo ""

printf "STEP 6.2: On MacOS\n\n"
echo "Execute below command on MacOS:"
echo "git clone https://github.com/alexzhangs/macos-aws-ses"
echo "sh macos-aws-ses/install.sh"
echo "macos-aws-ses-setup.sh -d $domain -r $region -u ${access_key_id:SMTP_USERNAME} -p ${smtp_secret_access_key:SMTP_PASSWORD} -t ${email:YOUR_EMAIL_ADDREESS}"
echo ""

exit
