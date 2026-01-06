# SemaphoreUI Host

Complete automation platform with Nginx Proxy Manager and PostgreSQL backend.

## Stack

- **SemaphoreUI** v2.16.47 - Ansible/Terraform automation UI
- **Nginx Proxy Manager** v2.13.5 - Reverse proxy with SSL
- **PostgreSQL** 17 - Database backend

## Network

- **Static IP**: 192.168.0.99/24
- **SSH**: Port 22 (key-based auth only)
- **HTTP/HTTPS**: Ports 80/443 (via NPM)
- **NPM Admin**: Port 81

## Default Credentials

### Nginx Proxy Manager
- **URL**: http://192.168.0.99:81
- **Email**: admin@example.com
- **Password**: changeme

### SemaphoreUI
- **URL**: http://192.168.0.99 (via NPM)
- **Username**: admin
- **Password**: changeme

### PostgreSQL
- **Database**: semaphore
- **Username**: semaphore
- **Password**: Auto-generated (see `/var/lib/semaphore/postgres_password`)

## Post-Install Steps

1. **Access NPM**: http://192.168.0.99:81 and change default credentials
2. **Configure SSL**: Set up Let's Encrypt certificates in NPM
3. **Create Proxy Host**: Point your domain to SemaphoreUI container
4. **Access SemaphoreUI**: http://192.168.0.99 and change default password
5. **Backup**: Important data is in `/var/lib/semaphore/`

## Data Persistence

All application data is stored in `/var/lib/semaphore/`:
- `postgres/` - PostgreSQL database
- `semaphore/` - SemaphoreUI configuration
- `npm/` - NPM configuration and SSL certificates
- `postgres_password` - Generated database password

## Updating

```bash
sudo -i
# Edit configuration
vim /opt/homelab-bootstrap/nix/hosts/semaphoreui/configuration.nix

# Apply changes
cd /opt/homelab-bootstrap/nix
nixos-rebuild boot --flake .#semaphoreui
reboot
```
