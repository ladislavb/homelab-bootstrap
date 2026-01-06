# semaphoreui

Automation and IaC management host with web UI.

## Stack

- **SemaphoreUI** (v2.16.47) - Ansible automation UI
- **Nginx Proxy Manager** (v2.13.5) - Reverse proxy with Let's Encrypt
- **PostgreSQL** (17) - Database

## Network

- Static IP: `192.168.0.99/24`
- Gateway: `192.168.0.1`

## Services

| Service | Port | Access |
|---------|------|--------|
| Nginx Proxy Manager | 80, 443, 81 | Public |
| SemaphoreUI | 3000 | Localhost only (via NPM) |
| PostgreSQL | - | Docker network only |

## Default Credentials

**SemaphoreUI:**
- Username: `admin`
- Password: `changeme` (change immediately!)

**Nginx Proxy Manager:**
- Admin UI: `http://<ip>:81`
- Use NPM default credentials on first login

## Secrets

- **Postgres password** - Auto-generated on first boot
  - Location: `/opt/docker4u/secrets/postgres_password`
  - Shared between SemaphoreUI and PostgreSQL containers

## Data Persistence

All data stored in `/opt/docker4u/`:
```
/opt/docker4u/
├── npm-data/           # NPM configuration
├── npm-letsencrypt/    # SSL certificates
├── semaphoreui/        # SemaphoreUI data
├── postgres/           # Database files
└── secrets/            # Auto-generated secrets
```

## Post-Installation

1. **Configure NPM**
   - Access `http://<ip>:81`
   - Add proxy host for SemaphoreUI:
     - Domain: `semaphore.yourdomain.com`
     - Forward to: `semaphoreui:3000`
   - Configure SSL (optional)

2. **Configure SemaphoreUI**
   - Access via NPM or `http://localhost:3000`
   - Change admin password
   - Add SSH keys
   - Connect GitHub repositories
   - Create task templates

## Backup

Important directories to backup:
- `/opt/docker4u/npm-data`
- `/opt/docker4u/semaphoreui`
- `/opt/docker4u/postgres`
- `/opt/docker4u/secrets`
