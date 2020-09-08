#!/bin/bash

# update hosts file
echo "[TASK 1] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.42.42.100 kmaster.firefly.local kmaster
172.42.42.101 kworker1.firefly.local kworker1
172.42.42.102 kworker2.firefly.local kworker2
EOF

echo "[TASK 2] Install docker"
