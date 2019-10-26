#? Description:
#?   Sign a secret access key as SMTP secret key.
#?
#? Usage:
#?   @sign <SECRET_ACCESS_KEY>
#?
#? Output:
#?   The signed SMTP secret key.
#?
function sign () {
    local secret_access_key=${1:?}

    local message="SendRawEmail"
    local version_in_bytes='\x02';

    local signature_in_bytes
    signature_in_bytes=$(openssl dgst -sha256 -hmac "$secret_access_key" -binary <<< "$message")
    base64 <<< "${version_in_bytes}${signature_in_bytes}"
}
