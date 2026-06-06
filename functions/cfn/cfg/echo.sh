#? Description:
#?   Print out the AWS CloudFormation Configuration Properties, which are
#?   defined by `XSH_AWS_CFN__CFG_PROPERTIES` in `cfn/__init__.sh`.
#?
#? Usage:
#?   @echo
#?
function echo () {
    declare item name

    for item in "${XSH_AWS_CFN__CFG_PROPERTIES[@]:?}"; do
        name=${item%%=*}
        declare | grep "^$name=" 2>/dev/null || :
    done
}
