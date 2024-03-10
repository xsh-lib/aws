# shellcheck disable=SC2148

#? -----------------------------------------------------------------------------
#? xsh library INIT file.
#?
#? This file is sourced while importing any function utility, right before the
#? function utility was sourced.
#?
#? The source of the init file won't happen again on the subsequence calls of
#? the function utility until it is imported again, except a `runtime` decorator
#? is used on the init file.
#?
#? All variables except those of Array should be exported in order to be
#? available for the sub-processes.
#?
#? The variables of Array can't be exported to the sub-processes due to the
#? limitation of Bash.
#? -----------------------------------------------------------------------------
#?
#? @runtime
#?

# shellcheck disable=SC2034

#? Parameter mappings from the manager stack output to the node stack input.
#?
#? Syntax:
#?   <manager stack output parameter>:<node stack input parameter>
#?
XSH_AWS_CFN_VPN__PARAM_MAPPINGS_MGR_OUTPUT_TO_NODE_INPUT=(
    AccountId:SSMAccountId
    VpcPeerAcceptorRegion:VpcPeerAcceptorRegion
    VpcId:VpcPeerAcceptorVpcId
    VpcPeerAcceptorSqsQueueUrl:VpcPeerAcceptorSqsQueueUrl
    IamPeerRoleArn:VpcPeerAcceptorRoleArn
    SnsTopicArnForConfig:SnsTopicArn
)
