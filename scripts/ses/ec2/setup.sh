#!/usr/bin/env bash

set -eo pipefail

#? Description:
#?   Setup Sendmail to use AWS SES service send email from EC2 instance.
#?   Run this script on the EC2 instance with sudo or as root.
#?
#? Usage:
#?   @setup
#?     -d SES_DOMAIN
#?     -r REGION
#?     -u SMTP_USERNAME
#?     -p SMTP_PASSWORD
#?     [-m SMTP_AUTH]
#?     [-t TEST_EMAIL]
#?
#? Options:
#?   -d SES_DOMAIN      Domain used by SES.
#?
#?   -r REGION          Region used by SES.
#?                        * us-east-1
#?                        * us-west-2
#?                        * eu-west-1
#?
#?   -u SMTP_USERNAME   Username for SES SMTP service.
#?
#?   -p SMTP_PASSWORD   Password for SES SMTP service.
#?
#?   [-m SMTP_AUTH]     SMTP authentication method.
#?                      The only one supported by SES is `PLAIN` (by 2019-07).
#?                      The default is `PLAIN`.
#?
#?   [-t TEST_EMAIL]    Send a test email after the setup.
#?
#? Reference:
#?   https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-sendmail.html
#?
#? Example:
#?   $ @setup -d example.com -r us-west-2 -u smtp_username -p smtp_password -m PLAIN
#?

# set default
SMTP_AUTH_METHOD=PLAIN

while getopts d:r:u:p:m:t opt; do
    case $opt in
        d)
            SES_DOMAIN=$OPTARG
            ;;
        r)
            REGION=$OPTARG
            ;;
        u)
            SMTP_USERNAME=$OPTARG
            ;;
        p)
            SMTP_PASSWORD=$OPTARG
            ;;
        m)
            SMTP_AUTH_METHOD=$OPTARG
            ;;
        t)
            TEST_EMAIL_SEND_TO=$OPTARG
            ;;
        *)
            exit 255
            ;;
    esac
done

if [[ -z $SES_DOMAIN || -z $REGION || -z $SMTP_USERNAME || -z $SMTP_PASSWORD ]]; then
    xsh log error "parameter null or not set"
    exit 255
fi

# sendmail-cf
echo "Installing sendmail-cf"
yum install -y m4 sendmail-cf

# /etc/mail/authinfo
echo "Modifying /etc/mail/authinfo"
cat > /etc/mail/authinfo << EOF
AuthInfo:email-smtp.${REGION}.amazonaws.com "U:root" "I:${SMTP_USERNAME}" "P:${SMTP_PASSWORD}" "M:${SMTP_AUTH_METHOD}"
EOF

# /etc/mail/authinfo.db
echo "Generating /etc/mail/authinfo.db"
makemap hash /etc/mail/authinfo.db < /etc/mail/authinfo

# /etc/mail/access
echo "Modifying /etc/mail/access"
LINE="Connect:email-smtp.${REGION}.amazonaws.com RELAY"
if ! grep "$LINE" /etc/mail/access; then
	echo "$LINE" >> /etc/mail/access
fi

# /etc/mail/access.db
echo "Generating /etc/mail/access.db"
makemap hash /etc/mail/access.db < /etc/mail/access

# Variables
mark_begin="# BEGIN == Generated by ${PROGNAME}"
mark_end="# END == Generated by ${PROGNAME}"
config="
define(\`SMART_HOST', \`email-smtp.${REGION}.amazonaws.com')dnl
define(\`RELAY_MAILER_ARGS', \`TCP \$h 25')dnl
define(\`confAUTH_MECHANISMS', \`LOGIN ${SMTP_AUTH_METHOD}')dnl
FEATURE(\`authinfo', \`hash -o /etc/mail/authinfo.db')dnl
MASQUERADE_AS(\`${SES_DOMAIN}')dnl
FEATURE(masquerade_envelope)dnl
FEATURE(masquerade_entire_domain)dnl
"

# /etc/mail/sendmail.mc
echo "Modifying /etc/mail/sendmail.mc"
xsh /file/inject -c "$config" \
       -p before \
       -e "^MAILER" \
       -m "$mark_begin" \
       -n "$mark_end" \
       -x "$mark_begin" \
       -y "$mark_end" \
       /etc/mail/sendmail.mc

# /etc/mail/sendmail.cf
echo "Generating /etc/mail/sendmail.cf"
m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf

# Restart Sendmail service
service sendmail restart

# Send test Email to verify the installation
if [[ -n $TEST_EMAIL_SEND_TO ]]; then
    echo "Sending test Email to $TEST_EMAIL_SEND_TO"
    sendmail -F "$PROGNAME" -f "no-reply@$SES_DOMAIN" -t << EOF
Subject: aws/ses/ec2/setup test Email
To: $TEST_EMAIL_SEND_TO
This is a test Email sent from AWS EC2 instance through AWS SES SMTP service.
EOF
fi

exit
