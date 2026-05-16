# Migration KWin -> niri

Kama Shell ne supporte plus KWin. La session unique est niri. Ce document
resume les etapes a suivre quand vous montez de la version KWin a la version
niri du projet.

## 1. Sauvegardes

Avant toute chose, sauvegardez votre configuration utilisateur:

```sh
cp -a ~/.config/kama-shell ~/.config/kama-shell.bak
cp -a ~/.config/niri ~/.config/niri.bak 2>/dev/null || true
```

Si vous aviez personnalise `~/.config/kwinrc` pour Kama Shell, sauvegardez
egalement ce fichier. Les scripts KWin (`kama-shell-shortcuts`,
`kama-shell-screenshot`) installes dans `~/.local/share/kwin/scripts/`
peuvent etre desinstalles: ils ne sont plus utiles.

## 2. Dependances

Sur Arch (paquet AUR `kama-shell`):

```sh
sudo pacman -S niri xwayland-satellite
yay -S quickshell-git
```

Recommande mais optionnel:

- daemon de notification: `mako`, `dunst` ou `swaync`
- agent polkit: `polkit-gnome` ou `polkit-kde-agent`
- portails: `xdg-desktop-portal-gnome` ou `xdg-desktop-portal-wlr`
- verrou/idle: `swayidle`, `swaylock`

## 3. Configuration niri

Copiez l'exemple installe avec le paquet:

```sh
mkdir -p ~/.config/niri
cp /usr/share/doc/kama-shell/niri-config.kdl.example ~/.config/niri/config.kdl
```

ou, depuis un clone du depot:

```sh
cp config/niri/config.kdl.example ~/.config/niri/config.kdl
```

Adaptez les sections `output` et `spawn-at-startup` a votre materiel. Les
binds niri par defaut sont fournis par un fichier separe; gardez l'include
suivant dans votre config niri:

```kdl
include optional=true "/usr/share/doc/kama-shell/niri-binds.kdl"
```

Le bind launcher par defaut est `Mod+D`.

Si vous lanciez Waybar, eww ou un autre dock, retirez-les de votre
autostart: Kama Shell rend deja dock, ring, launcher et wallpaper.

## 4. Configuration Kama Shell

La clef `launcher.shortcut` dans `~/.config/kama-shell/kama.conf` est
maintenant purement documentaire (niri possede les binds). Mettez-la a jour
pour qu'elle reflete le bind defini dans `niri-binds.kdl` ou dans votre config
niri afin de ne pas induire en erreur d'autres outils.

Le reste de `kama.conf` (theme, wallpaper, dock pinned apps) reste
applicable sans changement.

## 5. Session display manager

Installez la session niri:

```sh
make install-session-niri
```

ou installez le paquet (`kama-shell` sur Arch). Le fichier
`/usr/share/wayland-sessions/kama-shell-niri.desktop` apparait dans la
liste des sessions du display manager. Selectionnez "Kama Shell (niri)" a
la connexion.

Si vous demarrez depuis TTY:

```sh
exec niri-session
```

(apres avoir defini les variables d'environnement de la session, ou en
appelant directement `start-kama-shell-niri-session`).

## 6. Verifications

A la connexion verifiez que:

- Kama Shell apparait sur chaque ecran (ring, dock, wallpaper)
- le bind `Mod+D` ouvre et ferme le launcher
- une application fullscreen ne masque pas le launcher (layer overlay)
- les apps Wayland et Xwayland apparaissent dans le dock
- le clic sur une icone du dock active la fenetre correspondante
- les screenshots niri (`Print`, `Mod+Print`, `Mod+Shift+Print`) fonctionnent
- les notifications, polkit et portails se comportent normalement

Si une fonctionnalite manque, consultez [`TO_NIRI.md`](TO_NIRI.md) (matrice
de verification) et ajustez votre `config.kdl` ou les services systemd
utilisateur.
