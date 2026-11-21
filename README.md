### install

```bash
chmod +x init.sh
./init.sh
```

самоподписанный

mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/local.key -out certs/local.crt \
  -subj "/CN=*.docker.localhost"

или

$ mkcert -install
  Install the local CA in the system trust store.
 
$ mkcert "*.example.it"
Generate "_wildcard.example.it.pem" and "_wildcard.example.it-key.pem".




Create the Traefik Dashboard Credentials
In production, it is advisable to have some form of authentication/security for the Traefik dashboard. Traefik can be secured with the basic‑auth middleware. To do this, generate a hashed username / password pair that Traefik’s middleware will validate:


# sudo pacman -Syu apache

htpasswd -nb admin "P@ssw0rd" | sed -e 's/\$/\$\$/g'
Copy the full output (e.g., admin:$$apr1$$…) — we'll need this for the middleware configuration.












# Traefik

Centralized reverse proxy and TLS gateway for Docker-based applications.

This repository contains Traefik configuration for local development and production environments, including automatic HTTPS, Let's Encrypt certificates, dashboard authentication, and dynamic TLS configuration.

## Features

- Docker provider with automatic service discovery
- HTTP to HTTPS redirection
- Let's Encrypt certificate management
- Local HTTPS using self-signed certificates or `mkcert`
- Traefik Dashboard with Basic Authentication
- Dynamic TLS configuration
- Separate local and production Compose configurations

## Requirements

- Docker Engine
- Docker Compose v2
- OpenSSL
- `apache` (`htpasswd`) for Dashboard credentials
- `mkcert` (optional, for trusted local certificates)

## Project Structure

```text
traefik/
├── certs/
│   ├── .gitkeep
│   └── ...
├── dynamic/
│   └── tls.yaml
├── docker-compose.yml
├── docker-compose.prod.yml
├── env.example
├── .gitignore
├── init.sh
└── README.md
```

| Path | Description |
|---|---|
| `certs/` | TLS certificates and ACME storage |
| `dynamic/` | Dynamic Traefik configuration |
| `docker-compose.yml` | Local development configuration |
| `docker-compose.prod.yml` | Production configuration |
| `env.example` | Environment variables template |
| `init.sh` | Initial setup script |

## Installation

Clone the repository:

```bash
git clone <repository-url> traefik
cd traefik
```

Make the initialization script executable:

```bash
chmod +x init.sh
```

Initialize the environment:

```bash
./init.sh
```

The script prepares the required directories and files, initializes ACME storage, and can generate Dashboard credentials.

## Local Development

Local development requires a TLS certificate for `*.docker.localhost`.

Two certificate generation methods are supported.

### Option 1: Self-signed certificate

Generate a self-signed certificate using OpenSSL:

```bash
./init.sh --self-signed
```

Equivalent manual command:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/local.key \
  -out certs/local.crt \
  -subj "/CN=*.docker.localhost"
```

Browsers will display a certificate warning because the certificate is not issued by a trusted CA.

### Option 2: mkcert (recommended)

`mkcert` creates locally trusted certificates using a local Certificate Authority.

Install it:

```bash
# Arch Linux
sudo pacman -S mkcert nss
```

Install the local CA into the system trust store:

```bash
mkcert -install
```

Generate the certificate:

```bash
./init.sh --mkcert
```

This generates:

```text
certs/
├── local.crt
└── local.key
```

The certificate covers `*.docker.localhost`.

> Note: The local CA is installed on your development machine. Other devices will not automatically trust certificates issued by this CA.

## Production

Production uses Let's Encrypt for automatic certificate issuance and renewal.

Initialize the environment:

```bash
./init.sh
```

Configure the required environment variables using `env.example` as a reference:

```bash
cp env.example .env
nano .env
```

Start Traefik:

```bash
docker compose -f docker-compose.yml \
  -f docker-compose.prod.yml up -d
```

### ACME Storage

Traefik stores Let's Encrypt account information, certificates, and private keys in:

```text
certs/acme.json
```

The initialization script creates this file and sets permissions to `600`.

Do not delete this file unless you intentionally want to reset ACME storage.

## Dashboard Authentication

The Traefik Dashboard should never be exposed publicly without authentication.

The initialization script can generate a Basic Authentication configuration:

```text
dynamic/auth.yaml
```

The credentials are stored as an Apache-compatible password hash, not as plaintext.

To generate a hash manually:

```bash
htpasswd -nB admin
```

The resulting hash can be used in the dynamic middleware configuration.

Example:

```yaml
http:
  middlewares:
    dashboard-auth:
      basicAuth:
        users:
          - 'admin:$2y$05$...'
```

Enable the middleware on the Dashboard router:

```yaml
labels:
  - "traefik.http.routers.dashboard.middlewares=dashboard-auth@file"
```

## Useful Commands

Start Traefik:

```bash
docker compose up -d
```

Start production configuration:

```bash
docker compose -f docker-compose.yml \
  -f docker-compose.prod.yml up -d
```

View logs:

```bash
docker compose logs -f traefik
```

Restart:

```bash
docker compose restart traefik
```

Stop:

```bash
docker compose down
```

## Security Notes

- Never commit `.env`, `acme.json`, private keys, or Dashboard credentials.
- Keep `acme.json` permissions set to `600`.
- Use Basic Authentication for the Dashboard.
- Expose only the ports required by your deployment.
- Use Let's Encrypt certificates in production.
- Do not share your `mkcert` root CA private key.
- Keep Traefik and Docker images updated.

## License

Personal infrastructure configuration. Use and modify as needed.
