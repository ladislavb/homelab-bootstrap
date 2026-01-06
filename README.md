# Homelab bootstrap / recovery

* **1× NixOS VM** na Proxmoxu
* na ní běží **SemaphoreUI + Nginx Proxy Manager**
* po deploymentu defaultně **HTTP bez SSL**
* proxy host v NPM nastavíš **ručně**
* z té VM pak spustíš deployment celé infra z GitHub repa

## 0) Předpoklady (co musíš mít po ruce)

* přístup do Proxmoxu (root/SSH nebo UI)
* admin SSH key (abys se dostal po nixos-rebuild na VM)

## 1) Nainstaluj nový Proxmox host

1. Nainstaluj Proxmox (standard).
2. Nastav:

   * `vmbr0` (LAN/mgmt)
   * storage (ZFS/LVM-thin)
3. Ověř přístup: UI + SSH na host.

## 2) Vytvoř NixOS VM „semaphoreui“

1. V Proxmox UI:
   * Uploadni NixOS ISO (minimal).
2. Create VM:
   * CPU: 2 cores
   * RAM: 2 GB
   * Disk: 30 GB
   * NIC: virtio na `vmbr0`
3. Bootni z ISO a nainstaluj NixOS (minimal).
4. Během instalace nastav síť (DHCP stačí).
5. Nastav uživatele/admin.

## 3) Přihlášení na VM a stažení repa

1. Připoj se na VM:

```bash
ssh admin@<IP_VM>
```

2. Naklonuj repo:

```bash
sudo mkdir -p /opt/homelab
sudo chown admin:admin /opt/homelab
git clone https://github.com/ladislavb/homelab-bootstrap.git /opt/homelab
```

## 4) Aplikuj NixOS konfiguraci (Semaphore + NPM)

1. Přepni se do flake adresáře:

```bash
cd /opt/homelab/nix
```

2. Proveď rebuild:

```bash
sudo nixos-rebuild switch --flake .#semaphoreui
```

3. Ověř, že služby běží:

```bash
sudo systemctl status docker --no-pager
sudo docker ps
```

Měl bys vidět kontejnery typu:

* `npm`
* `semaphoreui`
* `semaphoreui-db`

## 5) Přístup do Nginx Proxy Manageru

1. Otevři v prohlížeči:

* `http://<IP_VM>:81`

2. Přihlas se do NPM (default) a hned změň heslo.
3. Zkontroluj, že NPM běží i na portu 80:

* `http://<IP_VM>/`

## 6) Nastav proxy host pro SemaphoreUI (ručně)

V NPM:

1. **Proxy Hosts → Add Proxy Host**
2. Domain Names:

* `semaphoreui.<doména>`

3. Scheme:

* `http`

4. Forward Hostname / IP:

* `semaphoreui`

5. Forward Port:

* `3000`

6. Save (bez SSL)

Pak zkus:

* `http://semaphoreui.<doména>`

> Pozn.: Aby ti `semaphore.<doména>` fungovalo hned, musí DNS ukazovat na IP té VM (interní split DNS nebo dočasně /etc/hosts).

## 7) Přihlášení do Semaphore a napojení GitHub repo

1. Otevři SemaphoreUI přes proxy:

* `http://semaphoreui.<doména>`

2. Přihlas se adminem (podle toho, co máš v Nix configu) a hned změň heslo.

3. V SemaphoreUI:

* přidej **Key Store / credentials**:
  * SSH key (pro přístup na servery)
  * GitHub token / deploy key (na clone repa)
* přidej **Repository** (tvůj IaC repo)
* nastav **Task templates** / Projects:
  * „TF Apply“ (pokud chceš spouštět tofu přes Semaphore)
  * „Ansible Deploy“
  * případně „Inventory render“ (pokud ho děláš)

## 8) Spusť deployment celé infrastruktury

Doporučené pořadí:

1. **TF/OpenTofu apply** (vytvoří infra)
2. **inventory generation** (pokud děláš z TF state)
3. **Ansible site** (konfigurace)

V SemaphoreUI:

* spusť job „bootstrap infra“ / „prod deploy“

## 9) Po stabilizaci: přepni na „komfortní režim“

* v NPM:
  * zapni SSL (Cloudflare DNS-01 nebo cokoliv ručně)
  * „Force SSL“
* omez přístup:
  * 80/81 (jen z mgmt/VPN)

## 10) Co zálohovat, aby další recovery byl ještě rychlejší

Minimální:

* `/opt/docker4u/npm-data`
* `/opt/docker4u/npm-letsencrypt`
* `/opt/docker4u/semaphoreui`
* `/opt/docker4u/postgres`
* `/opt/homelab` (nebo to jen znovu naklonuješ)

Ideální:

* celou VM přes backup v Proxmox + repo stále v GitHubu.

# Troubleshooting (nejčastější záseky)

* `semaphoreui.<doména>` nevede na VM → dočasně přidej do `/etc/hosts` na tvém PC.
* kontejnery neběží → `sudo docker ps -a` a `journalctl -u docker-npm -u docker-semaphore --no-pager`.
