#? -----------------------------------------------------------------------------
#? xsh library INIT file.
#?
#? This file is sourced while importing any function utility, right before the
#? function utility was sourced.
#? -----------------------------------------------------------------------------


XSH_AWS_CFG_DIR=~/.aws
XSH_AWS_CFG_CONFIG=${XSH_AWS_CFG_DIR}/config
XSH_AWS_CFG_CREDENTIALS=${XSH_AWS_CFG_DIR}/credentials

XSH_AWS_CFG_CONFIG_ENV_PREFIX=config_
XSH_AWS_CFG_CREDENTIALS_ENV_PREFIX=credentials_

XSH_AWS_CFG_PROPERTIES=(
    config.region
    credentials.aws_access_key_id
    credentials.aws_secret_access_key
    config.output
)
