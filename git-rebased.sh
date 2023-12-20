#!/usr/bin/bash
set -eu

#
# Utility funcs
#
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

RESET="~~~RESET~~~"

cprint () {
    # args: <color> <message>
    local color=$1
    local message=$2
    echo -e "$color${message//$RESET/$color}${ENDCOLOR}"
}

check_num_args() {
    local expected=$1
    local actual=$2
    if [[ $actual -ne $expected ]]; then
        cprint $RED ""
        cprint $RED "Wrong arguments count: $actual"
        usage 1 && exit -1
    fi
}

check_branch_exists() {
    local remote_branch=$1

    if ! git rev-parse --verify --quiet "$remote_branch"; then
        cprint $RED "remote branch $GREEN$remote_branch$RED was not found"
        exit -1
    fi
}


#
# Commands
#
cmd_push() {
    cprint $YELLOW "fetching latest data"
    git fetch --all

    # FIXME: detect remote from current stream
    local remote=origin
    local current=$(git rev-parse --abbrev-ref HEAD)
    local backup="backup/$current"
    local current_hash=$(git rev-parse HEAD)

    cprint $YELLOW "current hash is $BLUE$current_hash"

    if ! git rev-parse --verify --quiet "$remote/$backup"; then
        cprint $YELLOW "create $GREEN$remote/$current"

        # create backup branch
        git branch "$backup" "$remote/$current"
        git push origin "$backup:$backup"
        git branch -D "$backup"
    fi

    cprint $YELLOW "merge $GREEN$remote/$current$RESET and $GREEN$remote/$backup"
    # merge both backup and main branch (they can differ)
    git merge -s ours "$remote/$current" "$remote/$backup"

    cprint $YELLOW "push $GREEN$backup"
    git push origin "$current:$backup"

    cprint $YELLOW "restore $GREEN$current"
    git reset "$current_hash"

    # FIXME: make final check before push: remote target should not be changed since backup

    cprint $YELLOW "force push $GREEN$current"
    git push -f 

    cprint $GREEN "done."
}


rebase_using_backup() {
    local remote=$1
    local target_name=$2
    local target="$remote/$target_name"
    local target_backup="$remote/backup/$target_name"

    check_branch_exists "$target_backup"

    cprint $YELLOW "rebase on top of $GREEN$target_backup"
    git rebase "$target_backup"

    cprint $YELLOW "step back onto mainline"
    git rebase "$target_backup" --onto "$target_backup~"

    cprint $YELLOW "rebase to $GREEN$target"
    git rebase "$target"
}


cmd_pull() {
    cprint $YELLOW "fetching latest data"
    git fetch --all

    # FIXME: detect remote from current stream
    local remote=origin

    local current=$(git rev-parse --abbrev-ref HEAD)
    local current_hash=$(git rev-parse HEAD)
    cprint $YELLOW "current hash is $BLUE$current_hash"

    rebase_using_backup $remote $current

    cprint $GREEN "done."
}


cmd_rebase() {
    cprint $YELLOW "fetching latest data"
    git fetch --all

    local target=$1

    # FIXME: detect remote from current stream
    local remote=origin

    local current=$(git rev-parse --abbrev-ref HEAD)
    local current_hash=$(git rev-parse HEAD)
    cprint $YELLOW "current hash is $BLUE$current_hash"

    rebase_using_backup $remote $target

    cprint $GREEN "done."
}


#
# Parse command line
#
usage() {
    local is_error=${1:-0}
    local color=$CYAN
    if [[ $is_error -ne 0 ]]; then
        color=$RED
    else
        cprint $color ""
        cprint $color "Safe push and pull rebased streams"
    fi

    cprint $color ""
    cprint $color "Usage:"
    cprint $color "    git rebased push             # force-push rebased commits"
    cprint $color "    git rebased pull             # pull rebased upstream commits"
    cprint $color "    git rebased rebase TARGET    # rebase current branch onto other rebased branch"
}

POS_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--debug)
            set -x
            shift
            ;;
        -h|--help)
            usage && exit
            ;;
        -*|--*)
            echo $RED ""
            echo $RED "Unknown option: $1"
            usage 1 && exit -1
            ;;
        *)
            POS_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POS_ARGS[@]}"     # restore positional arguments

if [[ $# -eq 0 ]]; then
    usage && exit 0
fi

if [[ "$1" == "push" ]]; then
    check_num_args 1 $#
    cmd_push
elif [[ "$1" == "pull" ]]; then
    check_num_args 1 $#
    cmd_pull
elif [[ "$1" == "rebase" ]]; then
    check_num_args 2 $#
    cmd_rebase $2
else
    cprint $RED ""
    cprint $RED "Invalid command: $1"
    usage 1 && exit -1
fi
