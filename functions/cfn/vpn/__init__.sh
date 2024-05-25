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

XSH_AWS_CFN_VPN__CONFIG_VARS=(
    XACVC_XACC_STACK_NAME
    XACVC_XACC_ENVIRONMENT
    XACVC_XACC_RANDOM_STACK_NAME_SUFFIX
)

XSH_AWS_CFN_VPN__CONFIG_OPTIONS_VARS=(
    XACVC_XACC_OPTIONS_KeyPairName
    XACVC_XACC_OPTIONS_DomainNameServerEnv

    XACVC_XACC_OPTIONS_SSMAdminUsername
    XACVC_XACC_OPTIONS_SSMAdminPassword
    XACVC_XACC_OPTIONS_SSMAdminEmail
    XACVC_XACC_OPTIONS_SSMDomain
    XACVC_XACC_OPTIONS_SSMDomainNameServerEnv

    XACVC_XACC_OPTIONS_SSManagerPort
    XACVC_XACC_OPTIONS_SSEncrypt
    XACVC_XACC_OPTIONS_SSPortBegin
    XACVC_XACC_OPTIONS_SSPortEnd
    XACVC_XACC_OPTIONS_SSV2Ray
    XACVC_XACC_OPTIONS_SSDomain
    XACVC_XACC_OPTIONS_SSDomainNameServerEnv

    XACVC_XACC_OPTIONS_L2TPUsername
    XACVC_XACC_OPTIONS_L2TPPassword
    XACVC_XACC_OPTIONS_L2TPSharedKey
    XACVC_XACC_OPTIONS_L2TPDomain
    XACVC_XACC_OPTIONS_L2TPDomainNameServerEnv
)

#? Parameter mappings from the manager stack output to the node stack input.
#?
#? Syntax:
#?   <manager stack output parameter>:<node stack input parameter>
#?
XSH_AWS_CFN_VPN__CONFIG_OPTIONS_MAPPINGS_MGR_OUTPUT_TO_NODE_INPUT=(
    AccountId:SSMAccountId
    VpcPeerAcceptorRegion:VpcPeerAcceptorRegion
    VpcId:VpcPeerAcceptorVpcId
    VpcPeerAcceptorSqsQueueUrl:VpcPeerAcceptorSqsQueueUrl
    IamPeerRoleArn:VpcPeerAcceptorRoleArn
    SnsTopicArnForConfig:SnsTopicArn
)
