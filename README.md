# Frigate NVR auf Raspberry Pi 4

Frigate NVR auf einem dedizierten Raspberry Pi 4 (8GB) mit Google Coral USB TPU.
Gedacht als Auslagerung vom Hauptserver um diesen zu entlasten.

## Hardware

| Komponente | Details |
|---|---|
| Board | Raspberry Pi 4 Model B (8GB RAM) |
| OS | Raspberry Pi OS Lite 64-bit |
| Storage | Externe 2.5" HDD via USB für Recordings |
| Detector | Google Coral USB Edge TPU |
| Frigate | 0.17 |

---

## 1. Raspberry Pi vorbereiten

### 1.1 OS flashen

[Raspberry Pi Imager](https://www.raspberrypi.com/software/) herunterladen.

Empfohlene Einstellungen:
- **OS:** Raspberry Pi OS Lite (64-bit)
- **Hostname:** `pi-frigate`
- **SSH:** aktivieren
- **WLAN:** nicht konfigurieren — LAN-Kabel verwenden
- **Locale:** nach Bedarf

### 1.2 Erster Start & SSH

```bash
# IP im Router nachschauen oder per mDNS
ssh DEIN_USER@pi-frigate.local

# System aktualisieren
sudo apt update && sudo apt upgrade -y
sudo apt install -y htop curl git nano
```

### 1.3 Feste IP

DHCP-Reservierung im Router anhand der MAC-Adresse empfohlen —
kein statisches IP direkt am Pi nötig.

---

## 2. Externe HDD einrichten

```bash
# Gerät identifizieren
lsblk

# Mountpoint erstellen
sudo mkdir -p /mnt/frigate

# UUID ermitteln
sudo blkid /dev/sda1

# Manuell testen
sudo mount /dev/sda1 /mnt/frigate
ls /mnt/frigate
```

### Automount via fstab

```bash
sudo nano /etc/fstab
```

Zeile eintragen (UUID und Dateisystem anpassen):

```
UUID=DEINE-UUID  /mnt/frigate  ext4  defaults,nofail  0  2
```

> `nofail` — Pi startet auch wenn HDD nicht angeschlossen ist.

```bash
# Testen
sudo mount -a
df -h | grep frigate
```

---

## 3. Docker installieren

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Neu einloggen, dann testen:
docker run hello-world
```

---

## 4. Google Coral USB

Coral USB in einen **USB 3.0 Port** stecken (blauer Port am Pi 4).
Kein Treiber nötig — Docker übernimmt das beim ersten Start.

```bash
# Prüfen ob erkannt
lsusb | grep Google
# Erwartet: ID 18d1:9302 Google Inc.
```

> Coral USB neigt bei Dauerbetrieb zum Überhitzen.
> Direkt am Pi anschließen, keinen USB-Hub verwenden.

---

## 5. Frigate einrichten

### Verzeichnisstruktur

```bash
mkdir -p ~/frigate/config
```

### docker-compose.yml

Siehe [`docker-compose.yml`](docker-compose.yml) in diesem Repo.

### config.yml

`config.yml.example` kopieren und anpassen:

```bash
cp config/config.yml.example config/config.yml
nano config/config.yml
```

Platzhalter ersetzen:
- `IP_DES_HAUPTSERVERS` → IP des Servers auf dem Mosquitto läuft
- `USER:PASSWORT@IP_KAMERA_X` → RTSP-Zugangsdaten der Kameras

> Reolink-Streams:
> - `h264Preview_01_sub` = Substream → für `detect`
> - `h264Preview_01_main` = Hauptstream → für `record`

---

## 6. Frigate starten

```bash
cd ~/frigate
docker compose up -d

# Logs — Coral sollte erkannt werden
docker logs -f frigate
```

Erwartete Ausgabe:
```
detector.coral  INFO : Starting detection process
frigate.app     INFO : Recording process started
```

Web UI: `http://pi-frigate.local:5000`

---

## 7. Migration von bestehendem Server

```bash
# 1. Frigate auf altem Host stoppen
docker stop frigate

# 2. HDD sauber aushängen
sudo umount /mnt/DEIN_PFAD

# 3. HDD physisch umstecken → USB-Adapter → Pi

# 4. Coral USB umstecken → Pi

# 5. Frigate auf Pi starten
cd ~/frigate && docker compose up -d

# 6. Alten Container entfernen
docker rm frigate
```

---

## 8. Home Assistant Integration

MQTT-basiert — Frigate sendet Events an den MQTT-Broker.

- Frigate Host: `pi-frigate.local`
- Frigate Port: `5000`

MQTT-Broker kann auf einem anderen Server laufen —
`host` in `config.yml` entsprechend setzen.

---

## 9. Troubleshooting

**Coral nicht erkannt**
```bash
lsusb | grep -i google
docker exec frigate ls /dev/bus/usb
```

**Hohe CPU-Last trotz Coral**
Coral übernimmt nur Object Detection — Video-Dekodierung läuft immer auf der CPU.
Bei 4 Kameras @ 720p/5fps sind 50–70% CPU auf dem Pi 4 normal.
Bei dauerhaft über 85%: FPS auf 3–4 reduzieren.

**HDD wird nicht gemountet**
```bash
sudo mount -a   # zeigt Fehler in fstab
sudo blkid      # UUID nochmal prüfen
```

**shm_size Fehler**
Bei mehr als 2 Kameras @ 720p:
```yaml
shm_size: "512mb"
```

---

## 10. Nützliche Befehle

```bash
docker ps                    # Container Status
docker logs -f frigate       # Logs live
docker restart frigate       # Neustart
docker stats frigate         # Ressourcen
df -h /mnt/frigate           # Speicherplatz HDD
htop                         # System gesamt
```


