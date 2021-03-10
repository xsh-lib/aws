#? Description:
#?   Install the corresponding version of pip according to the Python version.
#?
#? Usage:
#?   @pip
#?
#? @xsh /trap/err -eE
#? @subshell
#?
function pip () {

    function curl-pip () {
        # -L: redo request on HTTP code 3XX
        # -f: fail mode
        # -s: silent mode
        # -v: verbose mode
        curl -Lfsv -o get-pip.py "$1"
    }

    if type pip >/dev/null 2>&1; then
        # installed already
        return
    fi

    # get the python version
    declare python_version=$(python --version 2>&1 | cut -c8-10)

    # get the specific version of pip
    curl-pip "https://bootstrap.pypa.io/pip/${python_version}/get-pip.py"

    # 22: maybe HTTP code 404 returned
    if [[ $? -eq 22 ]]; then
        # get the latest version of pip
        curl-pip "https://bootstrap.pypa.io/get-pip.py"
    fi

    python get-pip.py
}
