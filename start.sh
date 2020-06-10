#!/bin/bash
set -e

echo "IPAddress: $(hostname -I)"
source /etc/sysconfig/sshd

declare -a CRYPTO=("rsa" "ecdsa" "ed25519")

for TYPE in "${CRYPTO[@]}"; do
    test -f "/etc/ssh/ssh_host_${TYPE}_key" || /usr/libexec/openssh/sshd-keygen $TYPE
done

# clear nologin so users can login
if [ -e '/run/nologin' ]; then
    rm -f /run/nologin
fi

if [ ! -e /root/.ssh/id_rsa ]; then
    /usr/bin/ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ''
    echo "Generated Private Key:"
    cat /root/.ssh/id_rsa
fi
test -f /root/.ssh/authorized_keys || /usr/bin/cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

source /etc/crypto-policies/back-ends/opensshserver.config

/usr/sbin/sshd -D $OPTIONS $CRYPTO_POLICY
