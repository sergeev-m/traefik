# Traefik

Centralized reverse proxy and TLS gateway for Docker-based applications.

This repository provides Traefik configuration for local development and production environments, with automatic HTTPS, Let's Encrypt certificate management, and Docker service discovery.

## Features

- Docker provider with automatic service discovery
- HTTP to HTTPS redirection
- Let's Encrypt certificate management
- Local HTTPS using `mkcert` or self-signed certificates
- Traefik Dashboard with Basic Authentication
- Separate local and production Compose configurations

## Requirements

- Docker Engine
- Docker Compose v2
- OpenSSL
- `htpasswd` (optional, for Dashboard authentication)
- `mkcert` (optional, for trusted local certificates)

## Project Structure

```text
traefik/
├── certs/
│   └── .gitkeep
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
| `docker-compose.yml` | Local development configuration |
| `docker-compose.prod.yml` | Production configuration |
| `env.example` | Environment variables template |
| `init.sh` | Initial setup script |

## Installation

Clone the repository:

```bash
git clone git@github.com:sergeev-m/traefik.git
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

The script:

- Creates the `certs/` directory if it doesn't exist.
- Creates `certs/acme.json` if it doesn't exist.
- Sets `acme.json` permissions to `600`.

## Local Development

Local development requires a TLS certificate for `*.docker.localhost`.

Two certificate generation methods are available.

### Option 1: mkcert (recommended)

`mkcert` creates locally trusted certificates using a local Certificate Authority.

Install `mkcert`:

```bash
# Arch Linux
sudo pacman -S mkcert nss
```

Install the local CA into the system trust store:

```bash
mkcert -install
```

Generate a wildcard certificate:

```bash
mkcert "*.docker.localhost"
```

This generates two files in the current directory:

```text
_wildcard.docker.localhost.pem
_wildcard.docker.localhost-key.pem
```

Move them into the Traefik certificates directory:

```bash
mv _wildcard.docker.localhost*.pem certs/
```

The certificate covers subdomains such as:

- `app.docker.localhost`
- `api.docker.localhost`
- `dashboard.docker.localhost`

> Note: The local CA is installed only on your development machine. Other devices will not automatically trust certificates issued by this CA.

### Option 2: Self-signed certificate

Generate a self-signed certificate using OpenSSL:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/_wildcard.docker.localhost-key.pem \
  -out certs/_wildcard.docker.localhost.pem \
  -subj "/CN=*.docker.localhost" \
  -addext "subjectAltName=DNS:*.docker.localhost"
```

Set private key permissions:

```bash
chmod 600 certs/_wildcard.docker.localhost-key.pem
```

Browsers will display a certificate warning because the certificate is not issued by a trusted CA.

## Production

Production uses Let's Encrypt for automatic certificate issuance and renewal.

Initialize the environment:

```bash
./init.sh
```

Configure environment variables using `env.example`:

```bash
cp env.example .env
nano .env
```

Start Traefik:

#### Before the first launch, make sure that an external Docker network has been created:

```bash
docker network create roxy
```

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

This repository uses Traefik's Basic Authentication middleware configured through Docker labels.

### Generate credentials

Install `htpasswd`:

```bash
# Arch Linux
sudo pacman -S apache
```

Generate a bcrypt password hash:

```bash
htpasswd -nbB admin
```

Alternatively, provide the password directly:

```bash
htpasswd -nbB admin "P@ssw0rd"
```

Escape dollar signs for Docker Compose:

```bash
htpasswd -nbB admin "P@ssw0rd" | sed -e 's/\$/\$\$/g'
```

Copy the complete output, for example:

```text
admin:$$2y$$05$$...
```

### Configure Docker Compose

Add the generated credentials to `.env`:

```env
DASHBOARD_BASICAUTH=admin:$$2y$$05$$...
```

Configure the middleware and attach it to the Dashboard router:

```yaml
labels:
  - "traefik.http.middlewares.dashboard-auth.basicauth.users=${DASHBOARD_BASICAUTH}"
  - "traefik.http.routers.dashboard.middlewares=dashboard-auth"
```

Docker Compose converts `$$` into `$` when passing the value to the container.

Keep `.env` private and never commit it to the repository.

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
- Always protect the Dashboard with authentication.
- Expose only the ports required by your deployment.
- Use Let's Encrypt certificates in production.
- Do not share your `mkcert` root CA private key.
- Keep Traefik and Docker images updated.

## License

Personal infrastructure configuration. Use and modify as needed.
