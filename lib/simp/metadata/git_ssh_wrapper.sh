#! /bin/sh

ssh -i "${SSH_KEYFILE}" -o StrictHostKeyChecking=no "$@"
