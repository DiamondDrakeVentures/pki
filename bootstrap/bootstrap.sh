#!/bin/bash

CA_URL=https://martin.ghinfra.co
CA_FINGERPRINT=50bf30426b244a26c30e0a314ea9056ff8c19af501e6201293c1ed20f3cd3c1f
HC_KEY=
ACME_STANDALONE=0

while (( "$#" )); do
    case "$1" in
        --ca-url)
            if [[ -n "$2" ]]; then
                CA_URL=$2
                shift 2
            else
                echo "Argument for $1 is missing" >&2
                exit 1
            fi
            ;;

        --ca-fingerprint)
            if [[ -n "$2" ]]; then
                CA_FINGERPRINT=$2
                shift 2
            else
                echo "Argument for $1 is missing" >&2
                exit 1
            fi
            ;;

        --hc-key)
            if [[ -n "$2" ]]; then
                HC_KEY=$2
                shift 2
            else
                echo "Argument for $1 is missing" >&2
                exit 1
            fi
            ;;

        --standalone)
            ACME_STANDALONE=1
            shift 1
            ;;

        *)
            echo "Unsupported argument $1" >&2
            exit 1
            ;;
    esac
done

# Bootstrap CA
echo Bootstrapping CA
step ca bootstrap --ca-url $CA_URL \
                  --fingerprint $CA_FINGERPRINT \
                  --install
step ssh config --roots > $(step path)/certs/ssh_user_ca_key.pub

# Generate machine key
# Use a longer (30-day) ACME certificate so that the SSH host cert have longer validity
echo Authenticating with CA
if [[ $ACME_STANDALONE -eq 0 ]]; then
echo Authenticating in webroot mode
    step ca certificate --provisioner "acme" --webroot "/var/www/acme-challenge" \
                        --not-after 720h \
                        $(hostname --fqdn) $(hostname).crt $(hostname).key
else
echo Authenticating in standalone mode
    step ca certificate --provisioner "acme" --standalone \
                        --not-after 720h \
                        $(hostname --fqdn) $(hostname).crt $(hostname).key
fi

echo Requesting SSH host certificate
step ssh certificate --host --sign \
                     --x5c-cert $(hostname).crt \
                     --x5c-key $(hostname).key \
                     $(hostname --fqdn) \
                     /etc/ssh/ssh_host_ecdsa_key.pub

echo Backing up SSH config
mv /etc/ssh/sshd_config /etc/ssh/sshd_config.old

echo Downloading SSH config
curl -fsSL "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/sshd_config" \
    -o /etc/ssh/sshd_config

echo Downloading SSH host key renewal
curl -fsSL "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/rotate_ssh_certificate" \
    -o /etc/cron.weekly/rotate-ssh-certificate

echo Configuring SSH host key renewal
if [[ -n "$HC_KEY" ]]; then
    sed -i "s/HC_KEY=/HC_KEY=$HC_KEY/" /etc/cron.weekly/rotate-ssh-certificate
fi
chmod 755 /etc/cron.weekly/rotate-ssh-certificate

echo Revoking authentication with CA
step ca revoke --cert $(hostname).crt --key $(hostname).key

echo Cleaning up
rm -f $(hostname).crt $(hostname).key
rm -rf /init/ssh

echo Restarting SSH
systemctl restart ssh

echo Done!
