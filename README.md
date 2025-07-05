# PKI

Infrastructure code and configuration files related to the internal Public Key Infrastructure (PKI)
at Diamond Drake Ventures.

## Production Readiness

This repo is production ready in the sense that we use the configs and tools in this repo to deploy
our production environment.
Use them at your own risk.

## Bootstrapping

``` shell
curl -fsSL "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/bootstrap/bootstrap.sh" | sudo bash
```

By default, the bootstrap script uses the main DDV internal CA.
To use a different CA (e.g. local deployment), supply the URL (`--ca-url`) and fingerprint
(`--ca-fingerprint`).

``` shell
curl -fsSLO "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/bootstrap/bootstrap.sh"
sudo ./bootstrap.sh --ca-url <URL> --ca-fingerprint <fingerprint>
```

It is also possible to supply a [Healthchecks.io] API key.
When provided, scheduled tasks (e.g. SSH host certificate renewal) will ping using the key.

``` shell
curl -fsSLO "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/bootstrap/bootstrap.sh"
sudo ./bootstrap.sh --hc-key <API key>
```

## Updating

To remain up-to-date with this repo, each components provide a script wherever possible.

### Updating SSH

``` shell
curl -fsSLO "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/update.sh"
sudo ./update.sh --all
```

It is possible to update only the server configuration or the renewer script.

``` shell
curl -fsSLO "https://raw.githubusercontent.com/DiamondDrakeVentures/pki/refs/heads/main/ssh/update.sh"
# Update just the server config
sudo ./update.sh --server
# Update just the renewer
sudo ./update.sh --renewer
```

[Healthchecks.io]: https://healthchecks.io/
