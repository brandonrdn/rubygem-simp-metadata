#! /bin/sh
SSH_KEY=${SIMP_METADATA_SSHKEY:-""}
if [[ "${SSH_KEY}" != "" ]] ; then
    ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=no "$@"
else
    ssh -o StrictHostKeyChecking=no "$@"
fi