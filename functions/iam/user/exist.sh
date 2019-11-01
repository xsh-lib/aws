#? Description:
#?   Check the existence of IAM user.
#?
#? Usage:
#?   @exist [USERNAME]
#?
#? Return:
#?   0: yes
#?   1: no
#?
function exist () {
    declare query
    if [[ -n $1 ]]; then
        query="length(Users[?UserName=='$1'])"
    else
        query="length(Users)"
    fi

    test $(aws --query "$query" iam list-users) -gt 0
}
