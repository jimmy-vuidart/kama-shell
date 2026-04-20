# Intégrations système

## Dépendances Linux ciblées

- `NetworkManager` pour l’état réseau, SSID, trafic et VPN
- `BlueZ` pour l’état Bluetooth
- `UPower` pour la batterie
- `PipeWire` / `WirePlumber` pour l’audio
- `brightnessctl` ou lecture `/sys/class/backlight` pour la luminosité
- `systemd --user` et commandes système pour les actions de session
- `/proc` et `/sys` pour CPU, RAM et fallback réseau

## Stratégie par module

### Métriques système

- CPU : lecture de `/proc/stat`
- RAM : lecture de `/proc/meminfo`
- Réseau : `NetworkManager` en priorité, fallback `/sys/class/net`
- Horloge : temps système local avec polling léger

### Audio et luminosité

- audio via WirePlumber/PipeWire, fallback commande si nécessaire
- luminosité via `brightnessctl`, fallback `/sys/class/backlight`

### Launcher d’applications

- scan des fichiers `.desktop`
- parsing minimal : nom, icône, exec, catégorie

### Gaming

- détection Steam, Heroic, Lutris, ProtonUp-Qt
- scan des bibliothèques si présentes
- fallback propre en `empty state`

### Dev Workspace

- scan configurable de dossiers utilisateur
- détection projets via `.git`, `package.json`, `Cargo.toml`, `pyproject.toml`, `docker-compose.yml`
- actions rapides paramétrables

## Règles d’implémentation

- une intégration par adaptateur dédié
- aucun appel shell dispersé dans les composants UI
- tout fallback doit être explicite et documenté
- chaque widget important doit supporter `loading`, `empty` et `error`
