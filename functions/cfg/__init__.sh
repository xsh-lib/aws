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


export XSH_AWS_CFG_DIR=~/.aws
export XSH_AWS_CFG_CONFIG=${XSH_AWS_CFG_DIR:?}/config
export XSH_AWS_CFG_CREDENTIALS=${XSH_AWS_CFG_DIR:?}/credentials

export XSH_AWS_CFG_CONFIG_ENV_PREFIX=config_
export XSH_AWS_CFG_CREDENTIALS_ENV_PREFIX=credentials_

XSH_AWS_CFG_PROPERTIES=(
    config.region
    credentials.aws_access_key_id
    credentials.aws_secret_access_key
    config.output
)
