#!/bin/bash

UPDATE_SERVER=0
UPDATE_RENEWER=0

while (( "$#" )); do
    case "$1" in
        --all)
            UPDATE_SERVER=1
            UPDATE_RENEWER=1
            shift
            ;;

        --server)
            UPDATE_SERVER=1
            shift
            ;;

        --renewer)
            UPDATE_RENEWER=1
            shift
            ;;

        *)
            echo "Unsupported argument $1" >&2
    esac
done

update_server () {
    echo Backing up old server config
    mv -f /etc/ssh/sshd_config /etc/ssh/sshd_config.old

    echo Downloading updated server config
    curl -fsSL "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/sshd_config" \
        -o /etc/ssh/sshd_config
}

update_renewer () {
    echo Reading existing renewer config
    if [[ -f /etc/cron.weekly/rotate-ssh-certificate ]]; then
        eval "$(grep HC_KEY= /etc/cron.weekly/rotate-ssh-certificate)"
    fi

    echo Downloading updated renewer
    curl -fsSL "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/rotate_ssh_certificate" \
        -o /etc/cron.weekly/rotate-ssh-certificate

    echo Configuring updated renewer
    if [[ -n "$HC_KEY" ]]; then
        sed -i "s/HC_KEY=/HC_KEY=$HC_KEY/" /etc/cron.weekly/rotate-ssh-certificate
    fi
    chmod 755 /etc/cron.weekly/rotate-ssh-certificate
}

if [[ $UPDATE_SERVER -eq 1 ]]; then
    update_server
fi

if [[ $UPDATE_RENEWER -eq 1 ]]; then
    update_renewer
fi

if [[ $UPDATE_SERVER -eq 0 ]] && [[ $UPDATE_RENEWER -eq 0 ]]; then
    update_server
    update_renewer
fi
