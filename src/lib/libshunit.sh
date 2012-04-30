## Begin libshunit.sh

include common pretty parse

depends bc cat tail head grep egrep cut basename


## Automatically set name of the programm under test to the name
## of the test minus the extension ".test".
tprog=$(basename "$exname" .test)


function assert() {

    local md5 tmp_assert quiet func_usage desc code errorlevel retry

    func_usage="$FUNCNAME: [OPTION] {description} {command line}"

    [ -z "$1" -a -z "$2" ] && echo $func_usage && exit 1;

    quiet=""
    retry=""
    while true; do
        case "$1" in
            ("-q")
            quiet=true
            ;;
            ("-r")
            retry=true
            ;;
            ("")
            ;;
            (*)
            break
            ;;
        esac
        shift
    done

    desc=$1
    shift

    test -z "$__assert_count_total"     && __assert_count_total=0
    test -z "$__assert_count_failed"    && __assert_count_failed=0
    test -z "$__assert_count_succeeded" && __assert_count_succeeded=0
    test -z "$__assert_time_summary"    && __assert_time_summary=""

    Elt "$desc"
    print_info_char T

    if test "$*" == "-"; then
       code=$("$cat" -)
    else
       code=$*
    fi


    md5="$(echo "$code" | md5_compat)"
    tmp_assert="/tmp/assert.$md5.$$.tmp"

    if test "$retry"; then
       repeat_until "$code" > "$tmp_assert" 2>&1
    else
       timed_exec "$code" > "$tmp_assert" 2>&1
    fi

    errorlevel="$?"

    if test "$errorlevel" != "0"; then
        print_status failure
        Feed
        status=KO
    else
        [ "$quiet" ] || print_status success
        status=OK
    fi

    __assert_time_summary="$__assert_time_summary
$md5:$status:$exec_time:$desc"
    __assert_count_total=$[$__assert_count_total + 1]

    if [ "$errorlevel" == "0" ]; then
        rm "$tmp_assert"

        __assert_count_succeeded=$[$__assert_count_succeeded + 1]
        [ "$quiet" ] || Feed
        return 0
    fi

    [ "$quiet" ] || Feed
    __assert_count_failed=$[$__assert_count_failed + 1]

    [ "$retry" ] && echo "${YELLOW}++++++${WHITE} RETRY MODE (max_retries=$max_retries, sleep_time=$sleep_time)${NORMAL}"
    echo "${YELLOW}*****${WHITE} Full description:${NORMAL}"
    echo "$desc"
    echo "${YELLOW}*****${WHITE} code:${NORMAL}"
    echo "$code"
    echo "${YELLOW}>>>>> ${WHITE}Log info follows:$NORMAL"
    "$cat" "$tmp_assert"
    echo "${YELLOW}<<<<< ${WHITE}End Log."
    echo "${YELLOW}*****$NORMAL Errorlevel was : ${WHITE}$errorlevel${NORMAL}"

    return $errorlevel

}


function timed_exec() {

    local errorlevel beg_exec

    beg_exec=$(date +%s.%N)

    ( echo "$*" | bash )
    errorlevel=$?

    end_exec=$(date +%s.%N)

    exec_time="$(echo "scale=3; ($end_exec - $beg_exec)*1000000" | "$bc" | "$cut" -f 1 -d ".")"

    return $errorlevel
}


## XXXvlab: not finished !
function succeed_once() {

    func_usage="$FUNCNAME: {description} {nb_times} {wait_time} {code}"
    [ -z "$1" ] && echo $func_usage && exit 1;
    [ -z "$2" ] && echo $func_usage && exit 1;
    [ -z "$3" ] && echo $func_usage && exit 1;
    [ -z "$4" ] && echo $func_usage && exit 1;

    description=$1
    shift

    md5="$(echo "$*" | md5_compat)"
    tmp_assert="/tmp/assert.$md5.$$.tmp"

    print_info_char T
    Elt "$description"

    if test "$*" == "-"; then
       code=$("$cat" -)
    else
       code=$*
    fi
}


function assert_list () {

    local retry retry_opt

    func_usage="$FUNCNAME [OPTION] {description}"

    test "$__al_summary" || __al_summary=""
    test "$__al_quiet"   || __al_quiet=""

    while true; do
        case "$1" in
            ("-s")
            __al_summary=true
            ;;
            ("-q")
            __al_quiet=true
            ;;
            (*)
            break
            ;;
        esac
        shift
    done

    description=$*

    test "$description" -a "$__al_quiet" == "" && Title "$description"

    list=$("$cat" -)

    while test "$list" ; do

        line_header=$(echo "$list" | "$grep" "^##" -n -m 1 | "$cut" -f 1 -d ":")

        header=$(echo "$list" | "$head" -n "$line_header" | "$tail" -n 1)
        _tail=$(echo "$list" | "$tail" -n "+$[line_header + 1]")

        if test "$(echo "$header" | "$cut" -c 1-3)" == "###"; then
            Section "$(echo "$header" | "$cut" -c 4-)"
            list="$_tail"
            continue;
        fi

        next_header=$(echo "$_tail" | "$grep" "^##" -n -m 1 | "$cut" -f 1 -d ":")
        if test "$next_header" == ""; then
            code="$_tail"
            list=""
        else
            code=$(echo "$_tail" | "$head" -n "$[next_header - 1 ]")
            list=$(echo "$_tail" | "$tail" -n "+$[next_header]")
        fi

        retry=$(echo "$header" | "$cut" -f 2 -d "-" | remove trim-lines)
        desc=$(echo "$header" | "$cut" -f 3- -d "-" | remove trim-lines)

        if test -z "$desc" ; then
            desc="no description"
        fi

        if test -z "$code"; then
            break
        fi

        retry_opt=""
        if test "$retry" == "R"; then
            retry_opt="-r"
        fi

        if test $__al_quiet ; then
            assert "$retry_opt" -q "$desc" "$code"
        else
            assert "$retry_opt" "$desc" "$code"
        fi

        __assert_list_errorlevel=$?

        [ "$__assert_list_errorlevel" != "0" -a "$continue_on_error" != "" ] && break

    done

    test "$__al_quiet" -a "$__repress_feed" || Feed

    if [ "$__al_summary" ]; then
        Title "Assert List Summary ($__assert_count_total tests conducted)"
        test "$__assert_count_failed" != 0 && __assert_color=$RED || \
            __assert_color=$NORMAL

        Elt "$GREEN$__assert_count_succeeded$WHITE OK, $__assert_color$__assert_count_failed$WHITE Failed"
        Feed
    fi

    return $__assert_list_errorlevel

}


## XXXvlab: we have serious problem when including this code with shlib binary
## the quoting seem to be completely broken. So for now I'll deactivate this.
#function test_gnu_standards() {
#
#    Section Gnu Standards Tests
#
#    assert "$tprog --help sends errorlevel 0"        $tprog --help
#    assert "$tprog --version sends errorlevel 0"        $tprog --version
#
#    assert "$tprog --version sends version info"    matches \"$($tprog --version)\" \"$tprog ver\\\\. [0-9]\\\\+\\\\.[0-9]\\\\+\\\\.[0-9]\\\\+\"
#
#    assert "$tprog --help output contains info in first line" matches \"$($tprog --help | "$head" -n 1)\" \"$tprog ver\\\\. [0-9]\\\\+\\\\.[0-9]\\\\+\\\\.[0-9]\\\\+\"
#
#    assert "$tprog --help info are the same than $tprog --help" [ \"$($tprog --help | "$head" -n 1)\" == \"$($tprog --version)\" ]
#}


function testbench {

    local i j

    depends grep cut

    test -z "$__tb_count_total"     && __tb_count_total=0
    test -z "$__tb_count_failed"    && __tb_count_failed=0
    test -z "$__tb_count_succeeded" && __tb_count_succeeded=0

    test -z "$__assert_count_total"     && __assert_count_total=0
    test -z "$__assert_count_failed"    && __assert_count_failed=0
    test -z "$__assert_count_succeeded" && __assert_count_succeeded=0


    tmp_tb="/tmp/tb.$$.tmp"

    __tb_summary=""
    __tb_quiet=true

    while true; do
        case "$1" in
            ("-s")
            __tb_summary=true
            ;;
            ("-q")
            __tb_quiet=true
            export __repress_feed=true
            ;;
            (*)
            break
            ;;
        esac
        shift
    done


    more_args=""
    test -z "$*" && more_args=all

    t_func=$(set | "${egrep}" "^test_[a-zA-Z0-9_]+ ()" | "${cut}" -f 1 -d " " | "${cut}" -f 2- -d "_")

    for i in $t_func; do
        for j in $* $more_args ; do
            if [ "$i" == "$j" ] || [ "$j" == "all" ];  then
                Title Test $i
                export TEST_NAME="$i"

                if export -f "test_$i.setUp" >/dev/null 2>&1 ;then
                    Section setUp
                    eval "test_$i".setUp
                fi
                (
                    (eval "test_$i" );
                    echo "$?:$__assert_count_total:$__assert_count_failed:$__assert_count_succeeded" > "$tmp_tb"
                )

                ## Feed is needed because in the eval the pretty printing
                ## function Title, Section... might have been used. And their
                ## status cannot be tracked correctly:
                Feed

                return_values=$(cat "$tmp_tb")
                rm -f "$tmp_tb"

                __assert_count_total=$[ $__assert_count_total + $(echo "$return_values" | cut -f 2 -d ":")]

                __assert_count_failed=$[ $__assert_count_failed + $(echo "$return_values" | cut -f 3 -d ":")]

                __assert_count_succeeded=$[ $__assert_count_succeeded + $(echo "$return_values" | cut -f 4 -d ":")]

                __tb_errorlevel=$(echo "$return_values" | cut -f 1 -d ":")

                if export -f "test_$i.tearDown" >/dev/null 2>&1 ;then
                    Section tearDown
            (
                    eval "test_$i".tearDown
            )
                fi

                __tb_count_total=$[$__tb_count_total + 1]
                [ $__tb_errorlevel != "0" ] && __tb_count_failed=$[$__tb_count_failed + 1] || \
                    __tb_count_succeeded=$[$__tb_count_succeeded + 1]

                [ $__tb_errorlevel != "0" -a "$continue_on_error" != "" ] && break 2
            fi
        done
    done


    if [ "$__tb_summary" ]; then
        Title "Test Bench Summary ($__tb_count_total tests sequences conducted)"

        test "$__tb_count_failed" != 0 && __tb_color=$RED || __tb_color=$NORMAL

        Elt "Tests benchs: $GREEN$__tb_count_succeeded$WHITE OK, $__tb_color$__tb_count_failed$WHITE Failed"
        Feed

        test "$__assert_count_failed" != 0 && __assert_color=$RED || __assert_color=$NORMAL

        Elt "Tests: $GREEN$__assert_count_succeeded$WHITE OK, $__assert_color$__assert_count_failed$WHITE Failed"

        Feed
    fi

    return $__tb_errorlevel
}


function repeat_until() {
    local code errorlevel retries

    test -z "$sleep_time" && sleep_time=1
    test -z "$max_retries" && max_retries=10

    if test "$*" == "-"; then
       code=$("$cat" -)
    else
       code="$*"
    fi

    retries=0
    export errorlevel=1

    while true; do
        eval "$code"
        errorlevel=$?
        retries=$[$retries + 1]
        [ "$errorlevel" == 0 ] && return 0
        [ "$retries" -lt "$max_retries" ] || return 1
        sleep "$sleep_time"
    done
}


function testbenchdir {

    test_dir="$1"

    [ -d "$1" ] || print_error "couldn't find directory '$1'."

    for i in "$test_dir/test."* "$test_dir/"*.test; do

        [ -e "$i" ] || continue

        echo -n "-- " $i "..."

        if ! assert "$i"; then
            [ "$continue_on_error" == "1" ] || \
                print_error "At least one test failed."
        fi

    done

}

export -f repeat_until

## End libshunit.sh
