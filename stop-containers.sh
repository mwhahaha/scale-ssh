#!/bin/bash
#set -x
# blank this if you don't want sudo
SUDO_CMD="sudo"

CONTAINER_ENGINE=podman
CONTAINER_COUNT=${1:-100}
INSTANCE_FORMAT="ssh-%03d"
CONTAINER_INVENTORY="inventory.ini"

if ! command -v $CONTAINER_ENGINE >/dev/null; then
    echo "${CONTAINER_ENGINE} is not installed"
    exit 1
fi

check_cmd () {
    local CODE=${1:-0}
    local MSG=${2:-''}
    if [ "$CODE" != "0" ]; then
        echo "ERROR! $MSG"
        exit $1
    fi
}

stop_container ()  {
    local NAME=${1:-''}
    if [ -z "$NAME" ]; then
        echo "Missing container name"
        exit 1
    fi
    $SUDO_CMD $CONTAINER_ENGINE stop $NAME
    check_cmd $? "Stopping ${NAME} failed"

}

# create containers and generate inventory
for i in `seq 1 $CONTAINER_COUNT`; do
    NAME=$(printf "$INSTANCE_FORMAT" $i)
    echo "Stopping ${NAME}..."
    stop_container $NAME
done

# clear inventory
:> $CONTAINER_INVENTORY

