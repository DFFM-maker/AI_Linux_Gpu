# Configurazione Timeshift + Btrfs su EndeavourOS Hyprland

## 📋 Sistema di partenza

**Distribuzione:** EndeavourOS Mercury-Neo (2025.03.19)  
**Desktop Environment:** Hyprland (Wayland)  
**Bootloader:** systemd-boot  
**Filesystem:** Btrfs con subvolume layout  
**Disco:** `/dev/nvme0n1p2` (1TB disponibile)  
**Script installazione:** [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script)

### Installazione iniziale

```bash
# Clone repository script installazione Hyprland
git clone https://github.com/while1618/hyprland-install-script.git
cd hyprland-install-script/
./install.sh
```

**Note installazione:**
- EndeavourOS installato con modalità **Online** + **No Desktop**
- Hyprland installato successivamente via script
- Alcuni errori durante l'installazione script (risolti manualmente)

### Layout Btrfs iniziale

```
Subvolume layout:
- @ (root)
- @home
- @cache (/var/cache)
- @log (/var/log)
```

---

## 🎯 Obiettivo

Configurare un sistema di snapshot automatici con **Timeshift** per proteggere il sistema da:
- Aggiornamenti falliti del sistema
- Errori di configurazione
- Installazione di software problematici (es. KVM/QEMU, driver GPU)
- Modifiche al sistema che causano instabilità
- Rollback rapido in caso di problemi

---

## 🛠️ Installazione e Configurazione

### 1. Installazione Timeshift

```bash
# Installa Timeshift e dipendenze
sudo pacman -S timeshift cronie

# Abilita cronie per snapshot automatiche pianificate
sudo systemctl enable --now cronie
```

### 2. Configurazione iniziale Timeshift

```bash
# Prima configurazione via GUI (consigliata)
sudo timeshift-gtk

# Oppure via CLI
sudo timeshift --snapshot-device /dev/nvme0n1p2
```

**Impostazioni consigliate nella GUI:**
- **Mode:** BTRFS
- **Snapshot Location:** `/dev/nvme0n1p2` (disco sistema)
- **Include @home:** ✅ Yes (backup completo incluso home)
- **Restore @home:** ❌ No (evita sovrascrivere dati utente durante restore)

**Schedule (snapshot automatiche pianificate):**
- **Daily:** 5 snapshot (mantenute)
- **Weekly:** 3 snapshot (mantenute)
- **Monthly:** 0 (disabilitato)
- **Hourly:** 0 (disabilitato)
- **Boot:** 0 (disabilitato)

### 3. Abilita Quota Btrfs

Le quota Btrfs permettono a Timeshift di calcolare correttamente lo spazio occupato da ogni snapshot.

```bash
# Abilita quota
sudo btrfs quota enable /

# Avvia rescan (può richiedere 2-5 minuti su filesystem grandi)
sudo btrfs quota rescan /

# Monitora progresso rescan
sudo btrfs quota rescan -s /

# Verifica quota (dopo rescan completato)
sudo btrfs qgroup show /
```

**Output atteso dopo rescan:**
```
Qgroupid    Referenced    Exclusive   Path
--------    ----------    ---------   ----
0/256        15.2 GB       2.3 GB     @
0/257         8.5 GB       1.1 GB     @home
...
```

### 4. Crea snapshot manuali iniziali

```bash
# Prima snapshot - Sistema stabile base
sudo timeshift --create --comments "Sistema stabile - Hyprland funzionante" --tags O

# Snapshot prima di modifiche importanti
sudo timeshift --create --comments "Pre-KVM installation" --tags O

# Lista snapshot create
sudo timeshift --list
```

**Tags disponibili:**
- `O` = Ondemand (manuale)
- `D` = Daily (giornaliera)
- `W` = Weekly (settimanale)
- `M` = Monthly (mensile)
- `B` = Boot

### 5. Configura snapshot automatiche pre-pacman

**⚠️ IMPORTANTE:** Con systemd-boot (non GRUB), le snapshot **non appaiono automaticamente nel menu di boot**. Il rollback funziona comunque perfettamente via CLI o Live USB.

#### 5.1 Disabilita Snapper (se presente - conflitto con Timeshift)

```bash
# Verifica se snapper è installato
pacman -Qs snapper

# Se presente, disabilita timer
sudo systemctl disable --now snapper-timeline.timer
sudo systemctl disable --now snapper-cleanup.timer

# Rimuovi hook pacman di snapper
sudo rm -f /etc/pacman.d/hooks/snapper-*.hook

# (Opzionale) Rimuovi snapper completamente
sudo pacman -R snapper snap-pac --noconfirm
```

**Nota:** Snapper e Timeshift fanno la stessa cosa ma in modo incompatibile. Usare solo Timeshift.

#### 5.2 Crea hook Timeshift per pacman

Questo hook crea automaticamente una snapshot **prima** di ogni operazione pacman (`-S`, `-U`, `-R`).

```bash
# Crea directory hooks se non esiste
sudo mkdir -p /etc/pacman.d/hooks

# Crea hook file
sudo tee /etc/pacman.d/hooks/timeshift-autosnap.hook > /dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating Timeshift snapshot before package operation...
When = PreTransaction
Depends = timeshift
Exec = /usr/bin/timeshift --create --comments "Before pacman operation" --tags O --scripted
EOF

# Verifica creazione
cat /etc/pacman.d/hooks/timeshift-autosnap.hook

# Verifica permessi
ls -la /etc/pacman.d/hooks/
```

#### 5.3 Test hook

```bash
# Installa un pacchetto qualsiasi per testare
sudo pacman -S htop

# Durante l'installazione dovresti vedere:
# :: Running pre-transaction hooks...
# (1/1) Creating Timeshift snapshot before package operation...
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# ...
# BTRFS Snapshot saved successfully (0s)
```

✅ Se vedi questo output, l'hook funziona correttamente!

```bash
# Verifica snapshot creata
sudo timeshift --list
```

### 6. File di configurazione timeshift.json

Percorso: `/etc/timeshift/timeshift.json`

```json
{
  "backup_device_uuid" : "c0236b03-6890-4d91-b33c-d04619bdfa44",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "true",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
```

**Nota:** Sostituisci `backup_device_uuid` con l'UUID del tuo disco (ottenibile con `blkid`).

---

## 🔄 Utilizzo e Rollback

### Comandi base Timeshift

```bash
# Lista snapshot
sudo timeshift --list

# Crea snapshot manuale
sudo timeshift --create --comments "Descrizione personalizzata" --tags O

# Ripristina snapshot (interattivo)
sudo timeshift --restore

# Ripristina snapshot specifica
sudo timeshift --restore --snapshot '2025-11-20_08-24-08'

# Elimina snapshot
sudo timeshift --delete --snapshot '2025-11-20_08-24-08'

# Elimina tutte le snapshot
sudo timeshift --delete-all
```

### Rollback Metodo 1: Da sistema funzionante ✅

**Scenario:** Sistema boota ma ha problemi (es. driver GPU non funziona, Hyprland crashato, ecc.)

```bash
# 1. Ripristina interattivamente
sudo timeshift --restore

# 2. Seleziona snapshot desiderata (usa frecce + numero)
# 3. Conferma con ENTER
# 4. Attendi completamento
# 5. Riavvia
sudo reboot
```

**Nota:** Il restore sovrascrive il subvolume `@` corrente con quello della snapshot. Timeshift crea automaticamente una snapshot di pre-restore come backup.

### Rollback Metodo 2: Da Live USB (sistema non boota) 🛟

**Scenario:** Sistema non boota (schermata nera, kernel panic, ecc.)

```bash
# 1. Boot da USB Live EndeavourOS

# 2. Apri terminale

# 3. Monta il filesystem Btrfs (toplevel, subvolid=5)
sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs-root

# 4. Vedi le snapshot disponibili
ls -la /mnt/btrfs-root/timeshift-btrfs/snapshots/

# 5. Controlla se esiste un subvolume @ da sostituire
sudo btrfs subvolume list /mnt/btrfs-root | grep "path @$"

# 6. Se esiste, cancellalo
sudo btrfs subvolume delete /mnt/btrfs-root/@

# 7. Ricrea @ dalla snapshot desiderata (es. "2025-11-20_08-24-08")
sudo btrfs subvolume snapshot \
  /mnt/btrfs-root/timeshift-btrfs/snapshots/2025-11-20_08-24-08/@ \
  /mnt/btrfs-root/@

# 8. Verifica che @ sia stato creato
sudo btrfs subvolume list /mnt/btrfs-root | grep "path @$"

# 9. Smonta
cd /
sudo umount /mnt/btrfs-root

# 10. Rimuovi USB e riavvia
sudo reboot
```

### Rollback Metodo 3: Chroot da Live USB 🔧

**Scenario:** Sistema non boota, vuoi usare Timeshift dalla live USB.

```bash
# 1. Boot da USB Live EndeavourOS

# 2. Monta il sistema
sudo mount -o subvol=@ /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/efi  # Partizione EFI
sudo mount -o subvol=@home /dev/nvme0n1p2 /mnt/home

# 3. Chroot nel sistema
sudo arch-chroot /mnt

# 4. Usa Timeshift normalmente
timeshift --list
timeshift --restore

# 5. Esci da chroot
exit

# 6. Smonta e riavvia
sudo umount -R /mnt
sudo reboot
```

---

## 📊 Verifica stato sistema backup

### Script diagnostica completo

```bash
#!/bin/bash
echo "=== TIMESHIFT STATUS ==="
sudo timeshift --list

echo ""
echo "=== BTRFS SUBVOLUMES ==="
sudo btrfs subvolume list / | grep -E "@|timeshift"

echo ""
echo "=== BTRFS QUOTA ==="
sudo btrfs qgroup show / | head -20

echo ""
echo "=== PACMAN HOOKS ==="
ls -la /etc/pacman.d/hooks/

echo ""
echo "=== CRONIE STATUS ==="
systemctl status cronie --no-pager

echo ""
echo "=== DISK SPACE ==="
df -h / /home

echo ""
echo "=== TIMESHIFT CONFIG ==="
cat /etc/timeshift/timeshift.json | grep -E "schedule|count|btrfs"
```

Salva come `check-backup-system.sh`, rendi eseguibile e lancia:

```bash
chmod +x check-backup-system.sh
./check-backup-system.sh
```

---

## ⚠️ Note importanti

### systemd-boot vs GRUB

Questo sistema usa **systemd-boot** come bootloader, **non GRUB**.

**Implicazioni:**
- ❌ `grub-btrfs` e `grub-btrfsd` sono **inutili** (cercano GRUB che non c'è)
- ❌ Le snapshot **NON appaiono automaticamente** nel menu di boot
- ✅ Il rollback funziona **perfettamente** tramite CLI o Live USB
- ✅ Le snapshot sono salvate correttamente su disco

**Soluzioni tentate (non applicabili):**
```bash
# Questi comandi NON funzionano con systemd-boot
sudo grub-mkconfig -o /boot/grub/grub.cfg  # ❌ File non esiste
sudo systemctl enable grub-btrfsd          # ❌ Cerca /.snapshots (Snapper)
```

**Rollback consigliato per systemd-boot:**
1. Da sistema funzionante: `sudo timeshift --restore`
2. Da Live USB: metodo manuale (vedi sopra)

### Spazio disco e snapshot

**Calcolo spazio:**
- Snapshot Btrfs sono **incrementali** (solo differenze salvate)
- Una snapshot appena creata occupa ~0 byte
- Lo spazio cresce solo con le modifiche successive al filesystem
- Snapshot vecchie occupano più spazio (più differenze accumulate)

**Esempio:**
```
Snapshot 1 (oggi):         0 MB
Snapshot 2 (1 giorno fa):  500 MB  (differenze in 1 giorno)
Snapshot 3 (1 settimana):  2 GB    (differenze in 1 settimana)
```

**Gestione spazio:**
```bash
# Vedi spazio occupato da ogni snapshot (dopo quota rescan)
sudo btrfs qgroup show /

# Elimina snapshot vecchie
sudo timeshift --delete --snapshot 'NOME_SNAPSHOT'

# Elimina tutte le snapshot tranne le ultime N
# (Timeshift lo fa automaticamente in base a count_daily/weekly)
```

### Snapshot automatiche: frequency

Timeshift crea snapshot automatiche tramite **cron jobs**.

**Verifica cron:**
```bash
# Vedi timer cronie
sudo systemctl status cronie

# Vedi log cron
sudo journalctl -u cronie -f
```

**Snapshot vengono create:**
- **Daily:** Una volta al giorno (alla prima esecuzione dopo mezzanotte)
- **Weekly:** Una volta a settimana (domenica)
- **Pre-pacman:** Prima di ogni `pacman -S`, `pacman -U`, `pacman -R`

**Pulizia automatica:**
Timeshift elimina automaticamente le snapshot più vecchie quando superi i limiti configurati (es. 5 daily, 3 weekly).

### Esclusioni (opzionale)

Per **escludere** directory specifiche dalle snapshot, modifica `/etc/timeshift/timeshift.json`:

```json
{
  ...
  "exclude" : [
    "/var/cache/**",
    "/var/tmp/**",
    "/tmp/**",
    "/home/*/.cache/**"
  ],
  "exclude-apps" : []
}
```

**Nota:** Le esclusioni riducono lo spazio occupato dalle snapshot ma potrebbero rendere il restore incompleto.

---

## 🎯 Checklist finale

Dopo aver completato la configurazione, verifica:

- [ ] **Timeshift installato** e funzionante
- [ ] **Snapshot device** configurato (`/dev/nvme0n1p2`)
- [ ] **Snapshot pianificate** attive (daily/weekly)
- [ ] **Quota Btrfs** abilitate e rescan completato
- [ ] **Hook pacman** creato e testato
- [ ] **Snapper disabilitato** (se era presente)
- [ ] **Cronie attivo** (`systemctl status cronie`)
- [ ] **Almeno 1 snapshot manuale** creata e testata
- [ ] **Rollback testato** (da sistema funzionante)

**Test finale:**
```bash
# 1. Crea snapshot test
sudo timeshift --create --comments "Test finale" --tags O

# 2. Modifica un file di sistema
echo "test" | sudo tee /etc/test-timeshift.txt

# 3. Ripristina snapshot test
sudo timeshift --restore --snapshot 'NOME_SNAPSHOT_TEST'

# 4. Riavvia
sudo reboot

# 5. Verifica che il file sia sparito
ls /etc/test-timeshift.txt  # Dovrebbe dare "No such file"
```

---

## 📚 Risorse aggiuntive

- **Timeshift GitHub:** https://github.com/linuxmint/timeshift
- **Btrfs Wiki:** https://btrfs.wiki.kernel.org/
- **EndeavourOS Wiki:** https://discovery.endeavouros.com/
- **Hyprland install script:** https://github.com/while1618/hyprland-install-script

---

## 🐛 Troubleshooting

### Errore: "Quotas are not enabled"

```bash
sudo btrfs quota enable /
sudo btrfs quota rescan /
```

### Errore: "grub-btrfsd.service failed"

Normale con systemd-boot. Disabilita:
```bash
sudo systemctl disable --now grub-btrfsd
```

### Errore: "Snapper IO Error (.snapshots is not a btrfs subvolume)"

Snapper attivo ma configurato male. Rimuovi:
```bash
sudo pacman -R snapper snap-pac
```

### Hook pacman non crea snapshot

Verifica:
```bash
# Hook esiste?
cat /etc/pacman.d/hooks/timeshift-autosnap.hook

# Hook ha permessi corretti?
ls -la /etc/pacman.d/hooks/

# Test manuale
sudo /usr/bin/timeshift --create --comments "Test" --tags O --scripted
```

### Rollback non funziona (sistema non boota dopo restore)

1. Boot da Live USB
2. Monta filesystem: `sudo mount -o subvol=@ /dev/nvme0n1p2 /mnt`
3. Verifica `/mnt/etc/fstab` sia corretto
4. Reinstalla bootloader:
   ```bash
   sudo arch-chroot /mnt
   bootctl install
   exit
   ```
5. Riavvia

---

**Autore:** DFFM-maker  
**Data:** 2025-11-20  
**Sistema:** EndeavourOS Mercury-Neo 2025.03.19 + Hyprland (Wayland)  
**Script base:** [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script)

---

**Contributi e correzioni:** Se trovi errori o hai suggerimenti, apri una issue o PR su questo repository o su [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script).
