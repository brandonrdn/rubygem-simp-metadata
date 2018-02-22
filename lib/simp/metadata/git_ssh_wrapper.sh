#! /bin/sh
if [ "${SIMP_METADATA_SSHKEY}" != "" ] ; then
    ssh -i "${SIMP_METADATA_SSHKEY}" -o StrictHostKeyChecking=no "$@"
else
    ssh -o StrictHostKeyChecking=no "$@"
fi