#? -----------------------------------------------------------------------------
#? xsh library INIT file.
#?
#? This file is sourced while importing any function utility, right before the
#? function utility was sourced.
#?
#? All variables except those of Array should be exported in order to be
#? available for the sub-processes.
#?
#? The variables of Array can't be exported to the sub-processes due to the
#? limitation of Bash.
#? -----------------------------------------------------------------------------


XSH_AWS_CFN__CFG_SUPPORTED_VERSIONS=(
    0.1.0
)

XSH_AWS_CFN__CFG_PROPERTIES=(
    VERSION=
    STACK_NAME=
    ENVIRONMENT=
    RANDOM_STACK_NAME_SUFFIX=
    'DEPENDS=()'
    'LAMBDA=()'
    LOGICAL_ID=
    TIMEOUT=
    'OPTIONS=()'
    DISABLE_ROLLBACK=
    DELETE=
)

source /dev/stdin <<< "${XSH_AWS_CFN__CFG_PROPERTIES[@]}"

#? Index Explaination:
#?   index<100  : middle status
#?   index>=100 : final status
#?   index>=100 and (index%2)==0 : success status
#?   index>=100 and (index%2)==1 : failure statue
#?
XSH_AWS_CFN__STACK_STATUS=(
    [100]=CREATE_COMPLETE
    [201]=CREATE_FAILED
    [3]=CREATE_IN_PROGRESS

    [400]=DELETE_COMPLETE
    [501]=DELETE_FAILED
    [6]=DELETE_IN_PROGRESS

    [7]=REVIEW_IN_PROGRESS

    [801]=ROLLBACK_COMPLETE
    [901]=ROLLBACK_FAILED
    [10]=ROLLBACK_IN_PROGRESS

    [1100]=UPDATE_COMPLETE
    [12]=UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
    [13]=UPDATE_IN_PROGRESS
    [1401]=UPDATE_ROLLBACK_COMPLETE
    [15]=UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
    [1601]=UPDATE_ROLLBACK_FAILED
    [17]=UPDATE_ROLLBACK_IN_PROGRESS
)

#? Generate Variables:
#?   XSH_AWS_CFN__STACK_MIDDLE_STATUS
#?   XSH_AWS_CFN__STACK_FINAL_STATUS
#?   XSH_AWS_CFN__STACK_SUCCESS_STATUS
#?   XSH_AWS_CFN__STACK_FAILURE_STATUS
#?
declare i
for i in "${!XSH_AWS_CFN__STACK_STATUS[@]}"; do
    if [[ $i -lt 100 ]]; then
        XSH_AWS_CFN__STACK_MIDDLE_STATUS[i]=${XSH_AWS_CFN__STACK_STATUS[i]}
    else
        XSH_AWS_CFN__STACK_FINAL_STATUS[i]=${XSH_AWS_CFN__STACK_STATUS[i]}

        if [[ $((i % 2)) -eq 0 ]]; then
            XSH_AWS_CFN__STACK_SUCCESS_STATUS[i]=${XSH_AWS_CFN__STACK_STATUS[i]}
        else
            XSH_AWS_CFN__STACK_FAILURE_STATUS[i]=${XSH_AWS_CFN__STACK_STATUS[i]}
        fi
    fi
done
unset i
