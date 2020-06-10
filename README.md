scale-ssh
=========

SSH Container to emulate many hosts for basic scale testing

Usage
-----

```bash
# build the container
./build-container.sh

# copy public key for access
cp ~/.ssh/id_rsa.pub authorized_keys

# start up containers (100 by default)
./run-containers.sh

# run tests
ansible-playbook -i inventory.ini your-magical-playbook.yaml

# cleanup containers
./stop-containers.sh
```
