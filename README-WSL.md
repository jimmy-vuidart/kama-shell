# Installation de Quickshell sur WSL (ArchLinux) pour Hyprland

Ce guide explique comment configurer votre environnement WSL (ArchLinux) pour faire tourner ce `glass-shell` via Quickshell sur Hyprland.

## Pré-requis

1.  **WSL2** installé sur Windows 11 (pour le support natif de Wayland via WSLg).
2.  **ArchLinux** installé comme distribution WSL.
3.  **paru** (ou un autre assistant AUR comme `yay`) installé.

## Étape 1 : Mettre à jour et installer les dépendances de base

Utilisez `pacman` pour les paquets officiels :

```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel cmake git qt6-base qt6-declarative qt6-wayland wayland-protocols \
    mesa vulkan-intel vulkan-swrast libva-mesa-driver dbus xorg-xwayland
```

## Étape 2 : Configurer les Locales (Important pour Qt)

Si vous voyez des avertissements sur la locale `C`, activez une locale UTF-8 :

```bash
sudo sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
export LANG=en_US.UTF-8
```

## Étape 2 : Installer Hyprland et Quickshell

Avec `paru`, vous pouvez installer Hyprland et Quickshell (qui est disponible sur l'AUR) facilement :

```bash
paru -S hyprland-git quickshell-git
```
*(Note : Vous pouvez aussi utiliser les versions stables `hyprland` et `quickshell` si elles sont disponibles et à jour dans vos dépôts).*

Une fois installé, vous pouvez utiliser le script `wsl.sh` pour tout lancer :
```bash
./wsl.sh
```
Le script se chargera de lancer Hyprland en arrière-plan s'il ne tourne pas déjà, puis démarrera Quickshell.

Le script privilégie toujours le socket parent WSLg (`/mnt/wslg/runtime-dir/wayland-0`) quand il est disponible, afin d'éviter les boucles vers un socket nested local.

## Étape 3 : Lancement (Hyprland nested dans une fenêtre Windows)

1.  **Droits d'exécution** :
    ```bash
    chmod +x wsl.sh
    ```
2.  **Lancement unique recommandé** :
    ```bash
    ./wsl.sh
    ```
    Le script :
    - détecte le socket Wayland parent WSLg (`wayland-0`),
    - démarre Hyprland en mode nested (`WLR_BACKENDS=wayland`),
    - attend le socket enfant créé par Hyprland (souvent `wayland-1`),
    - lance Quickshell sur ce socket enfant.
3.  **Logs de diagnostic** :
    - Hyprland : `/tmp/glass-shell/hyprland.log`
    - Quickshell : `/tmp/glass-shell/quickshell.log`

## Notes sur WSLg

WSLg gère automatiquement le serveur Wayland. Quickshell devrait s'y connecter sans configuration complexe tant que la variable d'environnement `WAYLAND_DISPLAY` est correctement définie (par défaut `wayland-0`).

Si Quickshell ne se lance pas, essayez :
```bash
QT_QPA_PLATFORM=wayland quickshell shell.qml
```

## Dépannage (Erreurs EGL/Zink)

Si vous rencontrez des erreurs de type `MESA: error: ZINK: failed to load libvulkan.so.1` :

1.  **Drivers Vulkan** : Assurez-vous d'avoir `vulkan-intel` (Intel) ou `vulkan-radeon` (AMD) et `vulkan-swrast`.
2.  **CBackend::create() failed!** : Cette erreur signifie que Hyprland ne parvient pas à s'initialiser. Dans WSL, cela arrive souvent s'il n'est pas en mode "nested". Le script `wsl.sh` gère cela via `WLR_BACKENDS=wayland`. Assurez-vous que WSLg fonctionne (lancez `xclock` ou une autre application GUI simple pour vérifier).
3.  **Rien ne s'affiche** : Si Hyprland semble tourner mais qu'aucune fenêtre ne s'ouvre sur Windows :
    - Vérifiez `/tmp/hyprland.log` pour les erreurs.
    - Essayez de forcer le rendu logiciel : `WLR_RENDER_ALLOW_SOFTWARE=1 ./wsl.sh`.
    - Assurez-vous que `WAYLAND_DISPLAY` du parent est `wayland-0` (par défaut sur WSLg).
    - Vérifiez aussi que le socket parent est bien visible depuis `XDG_RUNTIME_DIR` :
      `ls -l "$XDG_RUNTIME_DIR"/wayland-0 /mnt/wslg/runtime-dir/wayland-0`
      (le script crée automatiquement un lien symbolique si nécessaire).
4.  **`Wayland backend cannot start: Missing protocols`** : Ce message indique en général qu'Hyprland nested s'est connecté au mauvais parent (souvent un autre Hyprland), au lieu du compositeur WSLg. Le script force désormais la priorité à `/mnt/wslg/runtime-dir/wayland-0` en WSL. Relancez simplement `./wsl.sh` et vérifiez dans les diagnostics imprimés la ligne `Parent Wayland socket=/mnt/wslg/runtime-dir/wayland-0`.
5.  **Layershell integration** : L'erreur `Failed to initialize layershell integration` survient si Quickshell n'est pas connecté au socket Hyprland nested. Le script gère cette détection automatiquement.
    - Vérifiez la présence d'un socket enfant : `ls -l "$XDG_RUNTIME_DIR"/wayland-*`
    - Vérifiez les logs : `tail -n 80 /tmp/glass-shell/hyprland.log`
6.  **DBus / Host Portal** : Si vous voyez `Failed to register with host portal`, installez `dbus` et relancez `./wsl.sh` (le script utilise `dbus-run-session` automatiquement si nécessaire).
