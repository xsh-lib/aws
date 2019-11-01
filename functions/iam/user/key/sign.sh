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
    declare secret_access_key=${1:?}

    declare message="SendRawEmail"
    declare version_in_bytes='\x02';

    declare signature_in_bytes
    signature_in_bytes=$(openssl dgst -sha256 -hmac "$secret_access_key" -binary <<< "$message")
    base64 <<< "${version_in_bytes}${signature_in_bytes}"
}
