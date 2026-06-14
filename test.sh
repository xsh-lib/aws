#!/bin/bash

# Make the `xsh` function available when this script is run as a child process.
# Under bash, xsh and the imported utilities are exported functions, so a child
# `bash test.sh` inherits them and this is a no-op. zsh cannot export functions,
# so a child `zsh test.sh` would otherwise only see the `bin/xsh` shim (which
# runs bash); sourcing ~/.xshrc here defines xsh as a real zsh function so the
# utilities execute under zsh's ksh emulation — the point of testing under zsh.
if ! type xsh 2>/dev/null | grep -q 'function'; then
    # shellcheck source=/dev/null
    . ~/.xshrc
fi

# NOTE: this suite deliberately does NOT use `set -e`. Many aws utilities end
# with a getopts/case loop and so return that loop's final (non-zero) status
# even on success — harmless in normal use, but under zsh's stricter ERR_EXIT a
# `$(util ...)` in a command substitution would abort the script. Assertions
# therefore compare captured output and tally failures explicitly.

__dir=$(cd "$(dirname "$0")" && pwd)
__fails=0

assert_eq () {  # <desc> <expected> <actual>
    if [ "$2" = "$3" ]; then
        printf 'ok   - %s\n' "$1"
    else
        printf 'FAIL - %s: expected [%s], got [%s]\n' "$1" "$2" "$3" >&2
        __fails=$((__fails + 1))
    fi
}

assert_rc_nonzero () {  # <desc> <cmd> [args...]  — util must exit non-zero
    if "${@:2}" >/dev/null 2>&1; then
        printf 'FAIL - %s: expected non-zero exit\n' "$1" >&2
        __fails=$((__fails + 1))
    else
        printf 'ok   - %s\n' "$1"
    fi
}

xsh log info 'xsh list aws/'
xsh list 'aws/*' >/dev/null

# ============================================================
# import-smoke: every function utility must source cleanly.
# The broadest portability check — under zsh each utility is sourced with the
# injected `emulate -L ksh`, so a syntax/runtime-substitution problem surfaces
# here. (scripts/ utilities are always executed via `bash` regardless of the
# caller's shell, so they need no zsh handling and are not smoked here; importing
# them would also need a writable /usr/local/bin.)
# ============================================================
xsh log info "import-smoke: all aws function utilities"
while read -r __lpue; do
    [ -z "$__lpue" ] && continue
    if xsh import "$__lpue" >/dev/null 2>&1; then
        :
    else
        printf 'FAIL - import %s\n' "$__lpue" >&2
        __fails=$((__fails + 1))
    fi
done < <(xsh list 'aws/*' | awk '$1 == "[functions]" {print $2}')
printf 'ok   - import-smoke (all function utilities sourced)\n'

# ============================================================
# aws/s3/uri/parser — pure URI parsing (uses BASH_REMATCH; zsh needs
# `setopt bash_rematch`, applied in the util)
# ============================================================
xsh log info "aws/s3/uri/parser"
assert_eq "s3/uri/parser -s s3://"        s3          "$(xsh aws/s3/uri/parser -s s3://mybucket/foo/bar.zip 2>/dev/null)"
assert_eq "s3/uri/parser -b s3://"        mybucket    "$(xsh aws/s3/uri/parser -b s3://mybucket/foo/bar.zip 2>/dev/null)"
assert_eq "s3/uri/parser -k s3://"        foo/bar.zip "$(xsh aws/s3/uri/parser -k s3://mybucket/foo/bar.zip 2>/dev/null)"
assert_eq "s3/uri/parser -b https"        mybucket    "$(xsh aws/s3/uri/parser -b https://mybucket.s3-ap-northeast-1.amazonaws.com/foo/bar.zip 2>/dev/null)"
assert_eq "s3/uri/parser -r https"        ap-northeast-1 "$(xsh aws/s3/uri/parser -r https://mybucket.s3-ap-northeast-1.amazonaws.com/foo/bar.zip 2>/dev/null)"
# China partition (host ends with .amazonaws.com.cn)
assert_eq "s3/uri/parser -r https (.cn)"  cn-north-1  "$(xsh aws/s3/uri/parser -r https://mybucket.s3.cn-north-1.amazonaws.com.cn/k 2>/dev/null)"

# ============================================================
# aws/s3/uri/translate — scheme translation between https and s3
# ============================================================
xsh log info "aws/s3/uri/translate"
assert_eq "s3/uri/translate https->s3" s3://mybucket/foo/bar.zip \
    "$(xsh aws/s3/uri/translate -s s3 https://mybucket.s3-ap-northeast-1.amazonaws.com/foo/bar.zip 2>/dev/null)"
assert_eq "s3/uri/translate s3->s3 (no-op)" s3://mybucket/foo/bar.zip \
    "$(xsh aws/s3/uri/translate -s s3 s3://mybucket/foo/bar.zip 2>/dev/null)"

# ============================================================
# aws/cfg/get — reads ~/.aws/{config,credentials} via /ini/parser and emits CSV
# (exercises the ${!var} name-indirection that was ported to portable `eval`).
# Uses a throwaway HOME so a real ~/.aws is never read or touched.
# ============================================================
xsh log info "aws/cfg/get (fixture config/credentials)"
__cfg_home=$(mktemp -d "${TMPDIR:-/tmp}/xsh-aws-cfg-test.XXXXXXXX")
mkdir -p "$__cfg_home/.aws"
cat > "$__cfg_home/.aws/config" <<'CFG'
[default]
region = us-east-1
output = json

[profile dev]
region = eu-west-1
output = text
CFG
cat > "$__cfg_home/.aws/credentials" <<'CRED'
[default]
aws_access_key_id = AKIADEFAULT
aws_secret_access_key = SECRETDEFAULT

[dev]
aws_access_key_id = AKIADEV
aws_secret_access_key = SECRETDEV
CRED

# cfg/get delegates the parsing to xsh-lib/core's /ini/parser. Older core
# releases ship an ini/parser.awk that aborts under gawk (most Linux) with
# "attempt to use scalar as an array" — fixed in core, but this test loads
# core's latest *stable tag*, which may predate that fix. Probe it and skip
# (rather than fail) the cfg/get assertions when /ini/parser is unusable, so
# this suite doesn't go red on a dependency-version mismatch.
if xsh /ini/parser -p __probe_ "$__cfg_home/.aws/config" >/dev/null 2>&1; then
    __saved_home=$HOME
    export HOME=$__cfg_home   # XSH_HOME is absolute/exported, so xsh stays anchored
    __cfg_default=$(xsh aws/cfg/get default 2>/dev/null)
    __cfg_all=$(xsh aws/cfg/get 2>/dev/null)
    export HOME=$__saved_home

    assert_eq "cfg/get default" "default,us-east-1,AKIADEFAULT,SECRETDEFAULT,json" "$__cfg_default"
    assert_eq "cfg/get all (line count)" 2 "$(printf '%s\n' "$__cfg_all" | grep -c ,)"
    case $__cfg_all in
        *"dev,eu-west-1,AKIADEV,SECRETDEV,text"*)
            printf 'ok   - cfg/get includes dev profile\n' ;;
        *)
            printf 'FAIL - cfg/get missing dev profile, got [%s]\n' "$__cfg_all" >&2
            __fails=$((__fails + 1)) ;;
    esac
else
    printf 'SKIP - cfg/get: xsh-lib/core /ini/parser unusable here (needs the gawk-safe ini/parser.awk fix)\n'
fi
rm -rf "$__cfg_home"

# ============================================================
# cfn STACK_STATUS classification table — the sparse-array build was rewritten
# to portable (code, name) pairs. Verify the derived value-sets are correct.
# Sourced in a subshell (the init file only assigns variables).
# ============================================================
xsh log info "cfn STACK_STATUS classification"
__stack_status_ok=$(
    # __init__.sh builds the table assuming bash-style 0-indexed arrays; xsh
    # supplies that via `emulate -L ksh` on import, so replicate it here when
    # sourcing the file directly under zsh. (No-op under bash.)
    [ -n "${ZSH_VERSION:-}" ] && emulate -L ksh
    # shellcheck source=/dev/null
    . "$__dir/functions/cfn/__init__.sh"
    rc=ok
    stable=" ${XSH_AWS_CFN__STACK_STATUS_STABLE[*]} "
    unstable=" ${XSH_AWS_CFN__STACK_STATUS_UNSTABLE[*]} "
    complete=" ${XSH_AWS_CFN__STACK_STATUS_COMPLETE[*]} "
    # STABLE holds steady states; UNSTABLE the *_IN_PROGRESS states
    [[ $stable == *" CREATE_COMPLETE "* ]]      || rc=bad-stable
    [[ $stable != *" CREATE_IN_PROGRESS "* ]]   || rc=stable-has-progress
    [[ $unstable == *" CREATE_IN_PROGRESS "* ]] || rc=bad-unstable
    [[ $complete == *" UPDATE_COMPLETE "* ]]    || rc=bad-complete
    printf '%s' "$rc"
)
assert_eq "cfn STACK_STATUS classification" ok "$__stack_status_ok"

# ============================================================
# argument validation — a utility that fails fast (early return, before any
# getopts loop) so its exit code is meaningful.
# ============================================================
xsh log info "aws/cfg/set (no profile = error)"
assert_rc_nonzero "cfg/set with empty profile errors" xsh aws/cfg/set ''

# ============================================================
printf '\n'
if [ "$__fails" -eq 0 ]; then
    xsh log info "aws tests: all passed"
    exit 0
else
    xsh log error "aws tests: ${__fails} failure(s)"
    exit 1
fi
