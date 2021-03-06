#? -----------------------------------------------------------------------------
#? xsh library INIT file.
#?
#? This file is sourced while importing any function utility, right before the
#? function utility was sourced.
#? -----------------------------------------------------------------------------


if [[ $(uname) != 'Linux' ]]; then
    printf "Error: this script supports Linux only.\n" >&2
    return 255
fi
