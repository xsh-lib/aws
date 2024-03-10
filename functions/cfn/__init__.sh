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

XSH_AWS_CFN__CFG_SUPPORTED_VERSIONS=(
    0.1.0
)

XSH_AWS_CFN__CFG_PROPERTIES=(
    VERSION=
    STACK_NAME=
    ENVIRONMENT=
    RANDOM_STACK_NAME_SUFFIX=
    'DEPENDS=()'
    'LAMBDA=()'
    LOGICAL_ID=
    TIMEOUT=
    'OPTIONS=()'
    DISABLE_ROLLBACK=
    DELETE=
)

# shellcheck source=/dev/null
source /dev/stdin <<< "${XSH_AWS_CFN__CFG_PROPERTIES[@]:?}"

#? AWS CloudFormation Stack Status Matrix:
#?
#? +--------------------------------------+-----------------------------------------------------+------------------------------------+
#? |                   /                  |                  SERVICEABLE (even)                 |         UNSERVICEABLE (odd)        |
#? +==================+===================+=====================================================+====================================+
#? |                  |                   |                              CREATE_COMPLETE (1200) |             DELETE_COMPLETE (1221) |
#? |                  |   SATISFIED (2xx) |                              UPDATE_COMPLETE (1230) |                                    |
#? |                  |                   |                              IMPORT_COMPLETE (1250) |                                    |
#? |                  +-------------------+-----------------------------------------------------+------------------------------------+
#? |    STABLE (1xxx) |                   |                            ROLLBACK_COMPLETE (1410) |               CREATE_FAILED (1403) |
#? |                  |                   |                     UPDATE_ROLLBACK_COMPLETE (1430) |             ROLLBACK_FAILED (1413) |
#? |                  | UNSATISFIED (4xx) |                     IMPORT_ROLLBACK_COMPLETE (1450) |               DELETE_FAILED (1423) |
#? |                  |                   |                                                     |               UPDATE_FAILED (1433) |
#? |                  |                   |                                                     |      UPDATE_ROLLBACK_FAILED (1435) |
#? |                  |                   |                                                     |      IMPORT_ROLLBACK_FAILED (1453) |
#? +------------------+-------------------+-----------------------------------------------------+------------------------------------+
#? |                  |   SATISFIED (2xx) |          UPDATE_COMPLETE_CLEANUP_IN_PROGRESS (9236) |                                  - |
#? |                  +-------------------+-----------------------------------------------------+------------------------------------+
#? |                  |                   | UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS (9436) |        ROLLBACK_IN_PROGRESS (9417) |
#? |                  | UNSATISFIED (4xx) |                                                     | UPDATE_ROLLBACK_IN_PROGRESS (9437) |
#? |                  |                   |                                                     | IMPORT_ROLLBACK_IN_PROGRESS (9457) |
#? |  UNSTABLE (9xxx) +-------------------+-----------------------------------------------------+------------------------------------+
#? |                  |                   |                                                   - |          CREATE_IN_PROGRESS (9607) |
#? |                  |                   |                                                     |          DELETE_IN_PROGRESS (9627) |
#? |                  |  SATISFYING (6xx) |                                                     |          UPDATE_IN_PROGRESS (9637) |
#? |                  |                   |                                                     |          REVIEW_IN_PROGRESS (9647) |
#? |                  |                   |                                                     |          IMPORT_IN_PROGRESS (9657) |
#? +------------------+-------------------+-----------------------------------------------------+------------------------------------+
#?
#? The text table is powered by: https://www.tablesgenerator.com/text_tables
#?

#? Index Explaination:
#?   ${index:0:1} == 1 : STABLE Status
#?   ${index:0:1} == 9 : UNSTABLE Status
#?
#?   ${index:1:1} == 2 : SATISFIED Statue
#?   ${index:1:1} == 4 : UNSATISFIED Status
#?   ${index:1:1} == 6 : SATISFYING Status
#?
#?   $((index%2)) == 0 : SERVICEABLE Status
#?   $((index%2)) == 1 : UNSERVICEABLE Status
#?
#?   ${index:2:1} == 0 : CREATE Status
#?   ${index:2:1} == 1 : ROLLBACK Status
#?   ${index:2:1} == 2 : DELETE Status
#?   ${index:2:1} == 3 : UPDATE Status
#?   ${index:2:1} == 4 : REVIEW Status
#?   ${index:2:1} == 5 : IMPORT Status
#?
#?   ${index:3:1} in [0,1] : COMPLETE Status
#?   ${index:3:1} in [2-5] : FAILED Status
#?   ${index:3:1} in [6-9] : INPROGRESS Status
#?
XSH_AWS_CFN__STACK_STATUS=(
    [9607]=CREATE_IN_PROGRESS
    [1403]=CREATE_FAILED
    [1200]=CREATE_COMPLETE

    [9617]=ROLLBACK_IN_PROGRESS
    [1413]=ROLLBACK_FAILED
    [1410]=ROLLBACK_COMPLETE

    [9627]=DELETE_IN_PROGRESS
    [1423]=DELETE_FAILED
    [1221]=DELETE_COMPLETE

    [9637]=UPDATE_IN_PROGRESS
    [9236]=UPDATE_COMPLETE_CLEANUP_IN_PROGRESS
    [1230]=UPDATE_COMPLETE
    [1433]=UPDATE_FAILED
    [9437]=UPDATE_ROLLBACK_IN_PROGRESS
    [1435]=UPDATE_ROLLBACK_FAILED
    [9436]=UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS
    [1430]=UPDATE_ROLLBACK_COMPLETE

    [9647]=REVIEW_IN_PROGRESS

    [9657]=IMPORT_IN_PROGRESS
    [1250]=IMPORT_COMPLETE
    [9457]=IMPORT_ROLLBACK_IN_PROGRESS
    [1453]=IMPORT_ROLLBACK_FAILED
    [1450]=IMPORT_ROLLBACK_COMPLETE
)

#? Generate Variables:
#?   XSH_AWS_CFN__STACK_STATUS_STABLE
#?   XSH_AWS_CFN__STACK_STATUS_UNSTABLE
#?
#?   XSH_AWS_CFN__STACK_STATUS_SATISFIED
#?   XSH_AWS_CFN__STACK_STATUS_UNSATISFIED
#?   XSH_AWS_CFN__STACK_STATUS_SATISFYING
#?
#?   XSH_AWS_CFN__STACK_STATUS_SERVICEABLE
#?   XSH_AWS_CFN__STACK_STATUS_UNSERVICEABLE
#?
#?   XSH_AWS_CFN__STACK_STATUS_CREATE
#?   XSH_AWS_CFN__STACK_STATUS_ROLLBACK
#?   XSH_AWS_CFN__STACK_STATUS_DELETE
#?   XSH_AWS_CFN__STACK_STATUS_UPDATE
#?   XSH_AWS_CFN__STACK_STATUS_REVIEW
#?   XSH_AWS_CFN__STACK_STATUS_IMPORT
#?
#?   XSH_AWS_CFN__STACK_STATUS_COMPLETE
#?   XSH_AWS_CFN__STACK_STATUS_FAILED
#?   XSH_AWS_CFN__STACK_STATUS_INPROGRESS
#?
declare index
for index in "${!XSH_AWS_CFN__STACK_STATUS[@]}"; do
    # XSH_AWS_CFN__STACK_STATUS_STABLE
    # XSH_AWS_CFN__STACK_STATUS_UNSTABLE
    case ${index:0:1} in
        1)
            XSH_AWS_CFN__STACK_STATUS_STABLE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        9)
            XSH_AWS_CFN__STACK_STATUS_UNSTABLE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
    esac
    
    # XSH_AWS_CFN__STACK_STATUS_SATISFIED
    # XSH_AWS_CFN__STACK_STATUS_UNSATISFIED
    # XSH_AWS_CFN__STACK_STATUS_SATISFYING
    case ${index:1:1} in
        2)
            XSH_AWS_CFN__STACK_STATUS_SATISFIED[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        4)
            XSH_AWS_CFN__STACK_STATUS_UNSATISFIED[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        6)
            XSH_AWS_CFN__STACK_STATUS_SATISFYING[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
    esac

    # XSH_AWS_CFN__STACK_STATUS_SERVICEABLE
    # XSH_AWS_CFN__STACK_STATUS_UNSERVICEABLE
    case $((index%2)) in
        0)
            XSH_AWS_CFN__STACK_STATUS_SERVICEABLE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        1)
            XSH_AWS_CFN__STACK_STATUS_UNSERVICEABLE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
    esac

    # XSH_AWS_CFN__STACK_STATUS_CREATE
    # XSH_AWS_CFN__STACK_STATUS_ROLLBACK
    # XSH_AWS_CFN__STACK_STATUS_DELETE
    # XSH_AWS_CFN__STACK_STATUS_UPDATE
    # XSH_AWS_CFN__STACK_STATUS_REVIEW
    # XSH_AWS_CFN__STACK_STATUS_IMPORT
    case ${index:2:1} in
        0)
            XSH_AWS_CFN__STACK_STATUS_CREATE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        1)
            XSH_AWS_CFN__STACK_STATUS_ROLLBACK[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        2)
            XSH_AWS_CFN__STACK_STATUS_DELETE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        3)
            XSH_AWS_CFN__STACK_STATUS_UPDATE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        4)
            XSH_AWS_CFN__STACK_STATUS_REVIEW[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        5)
            XSH_AWS_CFN__STACK_STATUS_IMPORT[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
    esac

    # XSH_AWS_CFN__STACK_STATUS_COMPLETE
    # XSH_AWS_CFN__STACK_STATUS_FAILED
    # XSH_AWS_CFN__STACK_STATUS_INPROGRESS
    case ${index:3:1} in
        [0,1])
            XSH_AWS_CFN__STACK_STATUS_COMPLETE[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        [2-5])
            XSH_AWS_CFN__STACK_STATUS_FAILED[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
        [6-9])
            XSH_AWS_CFN__STACK_STATUS_INPROGRESS[index]=${XSH_AWS_CFN__STACK_STATUS[index]}
            ;;
    esac
done
unset index
