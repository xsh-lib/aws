#? Description:
#?   Install packages with yum.
#?   Run this script on Linux under root.
#?
#? Usage:
#?   @install [-o] [-s] PACKAGE [...]
#?
#? Options:
#?   [-o]
#?
#?   Enable the service to start at system boot time.
#?   It's a wrapper of `chkconfig <PACKAGE> on`.
#?
#?   [-s]
#?
#?   Start the service after successfully installed the package.
#?   It's a wrapper of `service <PACKAGE> start`.
#?
#?   PACKAGE
#?
#?   The PACKAGE specifies the yum package name that will be installed.
#?   It's a wrapper of `yum install -y <PACKAGE>`.
#?
#? Example:
#?   @install nginx memcached
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function install () {
    declare on=0 start=0 packages \
            OPTIND OPTARG opt

    while getopts os opt; do
        case $opt in
            o)
                on=1
                ;;
            s)
                start=1
                ;;
            *)
                return 255
                ;;
        esac
    done
    shift $((OPTIND - 1))
    packages=( "$@" )

    declare name
    for name in "${packages[@]}"; do
        yum install -y "$name"
        if [[ $on -eq 1 ]]; then
            chkconfig "$name" on
        fi
        if [[ $start -eq 1 ]]; then
            service "$name" start
        fi
    done
}
