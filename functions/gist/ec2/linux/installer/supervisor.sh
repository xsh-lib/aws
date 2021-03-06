#? Description:
#?   Install supervisor with pip.
#?   Run this script under root on Linux.
#?
#? Usage:
#?   @supervisor [-i] [-o] [-s] [-v VERSION]
#?
#? Options:
#?   [-i]
#?
#?   Generate initd script, to enable `service supervisord <start|stop>`.
#?
#?   [-o]
#?
#?   Enable the service to start at system boot time.
#?   It's a wrapper of `chkconfig <NAME> on`.
#?   This option is valid only while the `-i` is specified.
#?
#?   [-s]
#?
#?   Start the service after successfully installed the package.
#?   It's a wrapper of `service <NAME> start`.
#?   This option is valid only while the `-i` is specified.
#?
#?   [-v VERSION]
#?
#?   Install a specific version, default is the latest version in pip.
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function supervisor () {
    declare package=supervisor initd_script=0 on=0 start=0 \
            OPTIND OPTARG opt

    while getopts iosv: opt; do
        case $opt in
            i)
                initd_script=1
                ;;
            o)
                on=1
                ;;
            s)
                start=1
                ;;
            v)
                package=supervisor==$OPTARG
                ;;
            *)
                return 255
                ;;
        esac
    done
    
    pip install "$package"
    mkdir -p /etc/supervisor/conf.d
    
    echo_supervisord_conf \
        | sed -e 's/;\[include]/[include]/' \
              -e 's|;files = .*|files = /etc/supervisor/conf.d/*.ini|' \
              > /etc/supervisord.conf
    
    if [[ $initd_script -eq 1 ]]; then
        # reference: https://github.com/alexzhangs/supervisord
        curl -Lfsv https://raw.githubusercontent.com/alexzhangs/supervisord/master/supervisord \
             -o /etc/init.d/supervisord
        chmod 755 /etc/init.d/supervisord
    fi
    
    if [[ $on -eq 1 ]]; then
        chkconfig supervisord on
    fi

    if [[ $start -eq 1 ]]; then
        service supervisord start
    fi
}
