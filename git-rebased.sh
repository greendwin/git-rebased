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


#
# Commands
#
cmd_push() {
    cprint $YELLOW "fetching latest data"
    git fetch --all

    # TODO: detect remote from current stream
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

    # TODO: make final check before push: remote target should not be changed since backup

    cprint $YELLOW "force push $GREEN$current"
    git push -f 

    cprint $GREEN "done."
}


cmd_pull() {
    cprint $YELLOW "fetching latest data"
    git fetch --all

    # TODO: detect remote from current stream
    local remote=origin
    local current=$(git rev-parse --abbrev-ref HEAD)
    local backup="backup/$current"
    local current_hash=$(git rev-parse HEAD)

    cprint $YELLOW "current hash is $BLUE$current_hash"

    if ! git rev-parse --verify --quiet "$remote/$backup"; then
        cprint $RED "backup branch $GREEN$remote/$backup$RESET was not found"
        exit -1
    fi

    cprint $YELLOW "rebase on top of $GREEN$remote/$backup"
    # merge both backup and main branch (they can differ)
    git rebase "$remote/$backup"

    cprint $YELLOW "move to mainline"
    git rebase "$remote/$backup" --onto "$remote/$backup~"

    cprint $YELLOW "rebase to $GREEN$remote/$current"
    git rebase "$remote/$current"

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
    cprint $color "    git rebased push         # force-push rebased commits"
    cprint $color "    git rebased pull         # pull rebased upstream commits"
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

if [[ $# -ne 1 ]]; then
    cprint $RED ""
    cprint $RED "Wrong arguments count: $#"
    usage 1 && exit -1
fi

if [[ "$1" == "push" ]]; then
    cmd_push
    exit
elif [[ "$1" == "pull" ]]; then
    cmd_pull
    exit
fi

cprint $RED ""
cprint $RED "Invalid command: $1"
usage 1 && exit -1
