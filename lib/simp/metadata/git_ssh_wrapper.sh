#! /bin/sh
if [ "${SSH_KEYFILE}" != "" ] ; then
    ssh -i "${SSH_KEYFILE}" -o StrictHostKeyChecking=no "$@"
else
    ssh -o StrictHostKeyChecking=no "$@"
fi