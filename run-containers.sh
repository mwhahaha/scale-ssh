#!/bin/bash
#set -x
SCRIPT_DIR=$(cd `dirname $0` && pwd -P)
# blank this if you don't want sudo
SUDO_CMD="sudo"

# network settings
NETWORK_NAME="pub_net"
NETWORK_SUBNET="172.16.86.0/24"
NETWORK_GATEWAY="172.16.86.1"

# container settings
CONTAINER="localhost/scale-ssh"
CONTAINER_ENGINE=podman
CONTAINER_COUNT=${1:-100}
CONTAINER_INVENTORY="inventory.ini"
INSTANCE_FORMAT="ssh-%03d"
INSTANCE_USER="root"
INSTANCE_AUTHORIZED_FILE="${SCRIPT_DIR}/authorized_keys"
INSTANCE_LOG_MOUNT="-v /dev/log:/dev/log -v /var/run/systemd/journal/socket:/var/run/systemd/journal/socket"

if ! command -v $CONTAINER_ENGINE >/dev/null; then
    echo "${CONTAINER_ENGINE} is not installed"
    exit 1
fi

if ! command -v jq >/dev/null; then
    echo "jq is not installed"
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

create_network () {
    echo "Creating network..."
    $SUDO_CMD $CONTAINER_ENGINE network create --subnet $NETWORK_SUBNET --gateway $NETWORK_GATEWAY $NETWORK_NAME
    check_cmd $? "Creating network failed"
}

spawn_container () {
    local NAME=${1:-''}
    if [ -z "$NAME" ]; then
        echo "Missing container name"
        exit 1
    fi
    $SUDO_CMD $CONTAINER_ENGINE run -d --rm $INSTANCE_LOG_MOUNT --network $NETWORK_NAME --name $NAME $CONTAINER
    check_cmd $? "Creating instance failed"
}

copy_authorized_keys () {
    local NAME=${1:-''}
    local FILENAME=${2:-''}
    if [ -z "$NAME" ]; then
        echo "Missing container name"
        exit 1
    fi
    if [ -z "$FILENAME" ]; then
        echo "Missing file name"
        exit 1
    fi
    $SUDO_CMD $CONTAINER_ENGINE cp $FILENAME $NAME:/root/.ssh/authorized_keys
    check_cmd $? "Copying authorized keys failed"
}

get_ipaddress () {
    local NAME=${1:-''}
    if [ -z "$NAME" ]; then
        echo "Missing container name"
        exit 1
    fi
    echo "$CMD"
    IPADDR=$($SUDO_CMD $CONTAINER_ENGINE inspect $NAME | jq -j ".[].NetworkSettings.Networks.$NETWORK_NAME.IPAddress")
    while [ -z "${IPADDR}" ] || [ "${IPADDR}" == "null" ]; do
        IPADDR=$($SUDO_CMD $CONTAINER_ENGINE inspect $NAME | jq -j ".[].NetworkSettings.Networks.$NETWORK_NAME.IPAddress")
    done
    echo -n "$IPADDR"
}

# ensure network is created
if ! $SUDO_CMD $CONTAINER_ENGINE network ls -q | grep -q $NETWORK_NAME; then
    create_network
fi



# clear inventory
:> $CONTAINER_INVENTORY

# create containers and generate inventory
for i in `seq 1 $CONTAINER_COUNT`; do
    NAME=$(printf "$INSTANCE_FORMAT" $i)
    echo "Spawning ${NAME}..."
    spawn_container $NAME
    IPADDR=$(get_ipaddress $NAME | tr -d '[:space:]')
    echo "IPADDR is ${IPADDR}"
    echo "${NAME} ansible_host=${IPADDR} ansible_user=${INSTANCE_USER}" >> $CONTAINER_INVENTORY
    if [ -e "${INSTANCE_AUTHORIZED_FILE}" ]; then
        copy_authorized_keys $NAME $INSTANCE_AUTHORIZED_FILE
    fi
done
echo "Inventory file: ${CONTAINER_INVENTORY}"

