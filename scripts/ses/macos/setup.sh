#!/usr/bin/env bash

set -eo pipefail

#? Description:
#?   Setup Sendmail to use AWS SES service send email from macOS.
#?   Run this script on the macOS with sudo or as root.
#?   Tested on macOS High Sierra.
#?
#? Usage:
#?   @setup
#?     -d SES_DOMAIN
#?     -r REGION
#?     -u SMTP_USERNAME
#?     -p SMTP_PASSWORD
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
#?   [-t TEST_EMAIL]    Send a test email after the setup.
#?
#? Reference:
#?   https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-sendmail.html
#?
#? Example:
#?   $ @setup -d yourdomain.com -r us-west-2 -u smtp_username -p smtp_password -m PLAIN
#?

get_postfix_service_name () {
    if launchctl list org.postfix.master >/dev/null 2>&1; then
        echo org.postfix.master
    elif launchctl list com.apple.postfix.master >/dev/null 2>&1; then
        echo com.apple.postfix.master
    else
        return 255
    fi
}

while getopts d:r:u:p:t opt; do
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

# Variables
mark_begin="# BEGIN == Generated by ${PROGNAME}"
mark_end="# END == Generated by ${PROGNAME}"
config="
relayhost = [email-smtp.${REGION}.amazonaws.com]:25
smtp_sasl_auth_enable = yes
smtp_sasl_security_options = noanonymous
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_use_tls = yes
smtp_tls_security_level = encrypt
smtp_tls_note_starttls_offer = yes
smtp_sasl_mechanism_filter = plain
"

# /etc/postfix/main.cf
echo "Modifying /etc/postfix/main.cf"
xsh /file/inject -c "$config" \
       -p after \
       -e "^#relayhost = \[an.ip.add.ress\]$" \
       -m "$mark_begin" \
       -n "$mark_end" \
       -x "$mark_begin" \
       -y "$mark_end" \
       /etc/postfix/main.cf

# /etc/postfix/sasl_passwd
echo "Modifying /etc/postfix/sasl_passwd"
cat > /etc/postfix/sasl_passwd << EOF
[email-smtp.${REGION}.amazonaws.com]:25 ${SMTP_USERNAME}:${SMTP_PASSWORD}
EOF

# /etc/postfix/sasl_passwd.db
echo "Generating /etc/postfix/sasl_passwd.db"
/bin/rm -f /etc/postfix/sasl_passwd.db
postmap /etc/postfix/sasl_passwd
chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Restart postfix service
service_name=$(get_postfix_service_name)
if [[ -n $service_name ]]; then
    launchctl stop $service_name
    launchctl start $service_name
else
    xsh log error "failed to get postfix service name"
    exit 255
fi

# Send test Email to verify the installation
if [[ -n $TEST_EMAIL_SEND_TO ]]; then
    echo "Sending test Email to $TEST_EMAIL_SEND_TO"
    sendmail -F "$PROGNAME" -f "no-reply@$SES_DOMAIN" -t << EOF
Subject: aws/ses/macos/setup test Email
To: $TEST_EMAIL_SEND_TO
This is a test Email sent from macOS through AWS SES SMTP service.
EOF
fi

exit
