# Migration vers niri

Ce document decrit le plan de migration de Kama Shell depuis une session centree sur KWin vers une session niri. L'objectif n'est pas de porter toute la logique en une fois, mais de separer proprement le shell Quickshell du compositeur, puis de faire de niri la cible principale.

## Decision cible

Kama Shell doit devenir un shell Quickshell autonome lance dans une session niri. niri devient la seule cible de session supportee par ce plan.

KWin ne doit pas rester supporte, meme temporairement, comme fallback ou backend legacy. Les integrations KWin actuelles doivent etre retirees du chemin de lancement, du packaging, des raccourcis, du dock et de la documentation utilisateur. La migration est consideree incomplete tant qu'un chemin fonctionnel depend encore de KWin, KRunner ou `kwriteconfig6`.

## Pourquoi niri

niri convient mieux a ce projet que KWin pour quatre raisons:

- c'est un compositeur Wayland autonome, pas un composant de Plasma;
- il documente une integration shell via layer-shell, IPC, systemd, autostart et desktop components;
- il expose un IPC JSON avec event stream, adapte aux etats de shell;
- il supporte les layer rules et les background effects pour les surfaces layer-shell.

Le compromis est important: Quickshell n'a pas de module niri dedie comparable a `Quickshell.Hyprland` ou `Quickshell.I3`. Les etats propres a niri devront donc passer par `niri msg --json` au debut, puis par un client IPC direct si le polling ou les processus deviennent trop couteux.

## Etat actuel a prendre en compte

Points deja compatibles:

- `src/shell.qml` compose des composants Quickshell sans logique KWin directe.
- `Ring`, `AppLauncherOverlay` et `WallpaperWindow` utilisent `Variants { model: Quickshell.screens }`.
- Les fenetres principales sont des `PanelWindow` avec `WlrLayershell`.
- Le dock utilise deja `ToplevelManager` comme source native quand le compositeur expose les toplevels.
- Le launcher global est expose via `IpcHandler` cible `kama-shell`; cette interface peut etre conservee.

Points KWin a supprimer:

- `sessions/kama-shell-session` lance `kwin_wayland` et configure `kwriteconfig6`.
- `sessions/kama-shell.desktop` annonce une session KWin.
- `PKGBUILD` depend de `kwin` et `plasma-workspace`.
- `kwin/scripts/kama-shell-shortcuts/` mappe le raccourci launcher vers `qs ipc`.
- `kwin/scripts/kama-shell-screenshot/` gere une integration de screenshot specifique KWin.
- `scripts/kwin-running-windows.py` et le fallback KRunner/DBus compensent les limites du backend toplevel sous KWin.
- `config/kama.conf.example` parle de sequence de touche KWin pour le launcher.

## Architecture cible

### Sessions

Ajouter une session niri explicite:

- `sessions/kama-shell-niri-session`: script de lancement de Kama Shell sous niri;
- `sessions/kama-shell-niri.desktop`: entree display manager pour la session;
- `config/niri/config.kdl.example` ou `sessions/niri-config.kdl.example`: exemple minimal de configuration niri pour Kama Shell.

La session niri ne doit pas installer ou modifier de configuration KDE. Elle doit:

- exporter `XDG_CURRENT_DESKTOP=KamaShell:niri` ou une valeur equivalente documentee;
- exporter `XDG_SESSION_DESKTOP=kama-shell-niri`;
- exporter `DESKTOP_SESSION=kama-shell-niri`;
- exporter `KAMA_SESSION=1`;
- lancer `quickshell -p src/shell.qml` via `run.sh` ou via un service utilisateur systemd;
- laisser niri gerer la session, les outputs et les services graphiques; les binds par defaut vivent dans un fichier KDL separe.

Attention: dans l'etat actuel, `KAMA_SESSION` et `XDG_CURRENT_DESKTOP` contenant `KamaShell` peuvent activer le fallback KRunner/KWin du dock. La session niri ne doit donc etre ajoutee comme chemin utilisable qu'apres la phase 0, quand ce fallback est supprime ou neutralise definitivement.

### Etat compositeur

Introduire une frontiere claire entre etat shell et compositeur, sans backend KWin:

- `state/CompositorState.qml`: detection du backend et capacites;
- `state/WindowState.qml`: liste normalisee des fenetres, active window, activation;
- `state/WorkspaceState.qml`: workspaces niri, output courant, overview si expose;
- `state/ShortcutState.qml` ou configuration documentee: source des raccourcis globaux.

Le rendu ne doit pas connaitre le backend. Les composants doivent consommer des structures normalisees:

```qml
{
    id: 12,
    appId: "org.gnome.Nautilus",
    title: "Home",
    desktopId: "org.gnome.Nautilus.desktop",
    iconName: "org.gnome.Nautilus",
    isFocused: true,
    workspaceId: 3,
    output: "DP-1",
    activate: function() {}
}
```

### IPC niri

Phase initiale:

- utiliser `Process` avec `niri msg --json ...` pour valider les donnees utiles;
- parser uniquement le JSON;
- ignorer les champs inconnus;
- eviter de dependre du format humain de `niri msg`.

Phase stable:

- remplacer les appels repetes a `niri msg` par un petit helper IPC;
- connecter le helper a `$NIRI_SOCKET`;
- envoyer les requetes JSON sur une ligne;
- lire les reponses JSON;
- maintenir un event stream long-running pour eviter le polling.

Ce helper peut etre ecrit en Python au debut si cela accelere le port, mais l'objectif doit rester de ne pas multiplier les processus par fenetre. Il doit etre instancie depuis un singleton Quickshell, pas depuis les composants visuels.

## Phases de migration

### Phase 0: cadrage et detection

Objectif: rendre visible le backend actif, interdire toute route KWin/KRunner, et ne pas toucher encore au rendu.

Taches:

- Ajouter `CompositorState.qml` avec `backend: "niri" | "generic-wlr" | "unknown"`.
- Detecter niri via `NIRI_SOCKET` ou `XDG_CURRENT_DESKTOP`.
- Ajouter une variable explicite `KAMA_COMPOSITOR=niri` pour les scripts de session; elle doit avoir priorite sur les heuristiques d'environnement.
- Exposer des capacites:
  - `hasNativeToplevels`;
  - `hasNiriIpc`;
  - `hasLayerRules`;
  - `supportsBackgroundEffect`.
- Supprimer le fallback KRunner/KWin du dock au lieu de le garder derriere une condition.
- Ne pas modifier le rendu.

Verification:

- lancer Quickshell dans une session niri existante;
- verifier que niri est detecte si `NIRI_SOCKET` est present.
- verifier que l'absence de niri ne reactive aucun chemin KWin ou KRunner.

### Phase 1: session niri minimale

Objectif: demarrer Kama Shell dans niri sans integration avancee.

Taches:

- Ajouter un script `sessions/kama-shell-niri-session`.
- Ajouter une entree `sessions/kama-shell-niri.desktop`.
- Exporter `KAMA_COMPOSITOR=niri`.
- Ajouter un exemple de config niri avec:
  - lancement de Kama Shell;
  - include optionnel du fichier de binds niri;
  - suppression ou non-lancement de Waybar pour eviter deux barres;
  - layer rules pour les namespaces Kama Shell.
- Mettre a jour le packaging pour installer la session niri et retirer la session KWin du paquet.
- Documenter les dependances:
  - `niri`;
  - `quickshell`;
  - `xwayland-satellite` pour les apps X11;
  - portals recommandes;
  - agent polkit;
  - notification daemon si Kama Shell ne le fournit pas encore.

Exemple d'include niri a viser dans la config utilisateur:

```kdl
include optional=true "/usr/share/doc/kama-shell/niri-binds.kdl"
```

Si la session continue a lancer `run.sh`, celui-ci doit rester neutre: il ne doit pas lancer un compositeur imbrique quand `NIRI_SOCKET` ou une session niri est active.

Verification:

- connexion depuis un display manager;
- connexion depuis TTY via `niri-session` si applicable;
- Kama Shell apparait sur tous les ecrans;
- le launcher s'ouvre via le bind niri;
- le hot reload Quickshell fonctionne encore.

### Phase 2: layer-shell et focus

Objectif: adapter les couches et le focus au comportement niri.

Taches:

- Garder le ring sur `WlrLayershell.Overlay` seulement si son comportement au-dessus des fullscreen est voulu.
- Garder le launcher sur `WlrLayershell.Overlay`, car niri documente que seule la couche overlay passe au-dessus d'une fenetre fullscreen.
- Evaluer si le ring passif doit descendre sur `Top` pour mieux cohabiter avec l'overview.
- Garder `WallpaperWindow` sur `Background`.
- Ajouter des layer rules niri pour les namespaces existants:
  - `kama-shell-ring`;
  - `kama-shell-launcher`;
  - `kama-shell-wallpaper`.
- Tester le comportement dans l'overview: les couches background/bottom zooment avec les workspaces, les couches top/overlay restent au-dessus.

Exemple de layer rules:

```kdl
layer-rule {
    match namespace="^kama-shell-launcher$"
    block-out-from "screencast"
}

layer-rule {
    match namespace="^kama-shell-ring$"
    block-out-from "screencast"
}
```

Points a verifier:

- launcher visible au-dessus des apps fullscreen;
- `WlrLayershell.keyboardFocus` du launcher recoit bien le clavier;
- clic hors launcher ferme l'overlay;
- le ring ne bloque pas les interactions avec les fenetres;
- le wallpaper ne capture jamais l'input.

### Phase 3: dock et fenetres ouvertes

Objectif: supprimer la dependance KRunner/KWin et utiliser une source native niri/wlroots.

Taches:

- Tester `ToplevelManager.toplevels` sous niri avec plusieurs apps Wayland et Xwayland.
- Supprimer `DockKrunnerFallback` et toute activation de `scripts/kwin-running-windows.py`.
- Si `ToplevelManager` est complet:
  - garder la resolution d'icones generique;
  - conserver les heuristiques `DesktopEntries`.
- Si `ToplevelManager` manque des champs utiles:
  - ajouter `NiriWindowBackend` base sur `niri msg --json windows`;
  - enrichir les items dock avec `workspace_id`, `is_focused`, `app_id`, `title`;
  - utiliser `niri msg action focus-window --id <id>` ou l'action equivalente documentee.
- Isoler la logique actuelle de `DockState.qml`:
  - `DockState` orchestre les items;
  - `DockIconResolver` resout les icones;
  - `NiriWindowBackend` fournit les fenetres niri.

Verification:

- apps pinned visibles au premier chargement;
- apps running non pinned ajoutees au dock;
- icones resolues au premier chargement;
- activation d'une fenetre depuis le dock;
- lancement d'une app pinned sans fenetre ouverte;
- plusieurs fenetres d'une meme app;
- apps Xwayland via `xwayland-satellite`;
- absence de polling inutile si l'event stream est en place.

### Phase 4: workspaces, outputs et UX niri

Objectif: utiliser les concepts niri sans casser l'identite Kama Shell.

Taches:

- Ajouter `WorkspaceState.qml` base sur l'IPC niri.
- Exposer:
  - outputs;
  - workspaces;
  - focused output;
  - focused workspace;
  - fenetres par workspace.
- Decider si Kama Shell affiche les workspaces niri dans le ring, le dock ou un futur module.
- Ajouter des actions shell:
  - focus workspace up/down;
  - toggle overview;
  - focus recent window;
  - move focused window si necessaire.
- Ne pas reproduire Waybar: afficher seulement les informations utiles au design Kama Shell.

Verification:

- multi-ecran avec workspaces independants;
- changement de workspace par bind niri;
- ajout/retrait d'ecran;
- overview niri avec ring, launcher et wallpaper;
- coherence du focus apres fermeture du launcher.

### Phase 5: raccourcis globaux

Objectif: retirer les scripts KWin de raccourcis et confier les raccourcis globaux a niri.

Taches:

- Pour niri, definir les binds dans un fichier separe (`config/niri/binds.kdl`), pas dans Quickshell.
- Conserver `KamaShellIpc.qml` comme API stable:
  - `toggleLauncher [screenName]`;
  - futurs appels: screenshot, settings, theme reload.
- Ajouter une cle de config neutre cote Kama Shell si necessaire:
  - `launcher.shortcut` devient une documentation de bind, pas une configuration appliquee par Kama Shell;
  - ou ajouter `session.applyShortcut = false` pour les backends ou le WM gere les binds.
- Mettre a jour `config/kama.conf.example` si le sens de `launcher.shortcut` change.
- Supprimer `kwin/scripts/kama-shell-shortcuts/` du chemin installe.

Verification:

- bind niri ouvre le launcher;
- changement de raccourci documente dans `config/niri/binds.kdl` et reference depuis `config.kdl.example`;
- aucune tentative `kwriteconfig6` ne reste dans le chemin de session.

### Phase 6: screenshots et services desktop

Objectif: remplacer les integrations KWin annexes par des outils ou APIs compatibles niri, puis retirer les scripts KWin.

Taches:

- Evaluer les actions screenshot natives de niri:
  - `screenshot`;
  - `screenshot-screen`;
  - `screenshot-window`.
- Decider si Kama Shell garde un module screenshot propre ou delegue aux binds niri.
- Supprimer `kwin/scripts/kama-shell-screenshot/` du chemin installe.
- Documenter les services minimaux:
  - portals;
  - notification daemon;
  - polkit agent;
  - idle/lock;
  - xwayland-satellite.
- Preferer systemd user services rattaches a `niri.service` pour les services persistants.

Verification:

- screenshot region;
- screenshot fenetre;
- copie clipboard;
- portail screencast;
- apps Flatpak;
- auth polkit.

### Phase 7: packaging et documentation

Objectif: faire de niri une cible installable propre.

Taches:

- Adapter `PKGBUILD`:
  - remplacer les dependances `kwin` et `plasma-workspace` par les dependances niri;
  - installer uniquement l'entree de session niri;
  - ne plus copier `kwin/` dans le paquet.
- Ajouter un exemple de config niri installe dans la doc.
- Mettre a jour `AGENTS.md` quand la structure actuelle change.
- Mettre a jour `PLAN.md` seulement si la cible officielle change.
- Ajouter une section migration utilisateur:
  - sauvegarder `~/.config/niri/config.kdl`;
  - installer les dependances;
  - copier ou inclure la config Kama Shell;
  - desactiver Waybar;
  - selectionner la session dans le display manager.

Verification:

- installation depuis paquet;
- session visible dans le display manager;
- uninstall sans laisser de scripts KWin installes;
- upgrade sans ecraser la config utilisateur.

### Phase 8: retrait complet de KWin

Objectif: supprimer KWin du projet comme cible supportee.

Taches:

- Supprimer `kwin/`.
- Supprimer `scripts/kwin-running-windows.py`.
- Supprimer `DockKrunnerFallback`.
- Supprimer la session KWin et son entree `.desktop`.
- Nettoyer `PKGBUILD`.
- Renommer les commentaires de config qui mentionnent KWin.
- Supprimer les variables, fonctions et chemins de code lies a `kwriteconfig6`, KRunner et `org.kde.KWin`.

Ce retrait n'est pas optionnel dans ce plan. Il peut etre fait en plusieurs PR pour garder une verification lisible, mais aucune PR finale ne doit conserver de fallback KWin fonctionnel.

## Changements de fichiers proposes

Nouveaux fichiers:

- `docs/TO_NIRI.md`
- `sessions/kama-shell-niri-session`
- `sessions/kama-shell-niri.desktop`
- `config/niri/config.kdl.example`
- `src/state/CompositorState.qml`
- `src/state/NiriIpc.qml`
- `src/state/NiriWindowBackend.qml`
- `src/state/NiriWorkspaceState.qml`

Fichiers a modifier:

- `src/state/qmldir`: declarer les nouveaux singletons.
- `src/state/DockState.qml`: consommer un backend de fenetres abstrait.
- `src/ipc/KamaShellIpc.qml`: conserver l'API et ajouter des appels seulement si necessaire.
- `config/kama.conf.example`: retirer les formulations KWin-only.
- `PKGBUILD`: remplacer les dependances et fichiers installes par la cible niri.
- `AGENTS.md`: mettre a jour la structure actuelle quand les composants deviennent durables.

Fichiers a supprimer:

- `kwin/`
- `scripts/kwin-running-windows.py`
- `src/state/DockKrunnerFallback.qml`
- `sessions/kama-shell-session`
- `sessions/kama-shell-debug-session`
- `sessions/kama-shell.desktop`

Fichiers a ne pas modifier au debut:

- `src/components/Ring.qml`, sauf ajustement de couche apres test.
- `src/components/AppLauncherOverlay.qml`, sauf si le focus niri impose un changement.
- `src/components/WallpaperWindow.qml`, sauf layer rule ou namespace.

## Risques

### Pas de module Quickshell niri natif

Risque: trop de `Process` et de parsing disperses.

Mitigation: un seul singleton `NiriIpc.qml`, puis un helper socket long-running si necessaire.

### Differences entre toplevel Wayland et IPC niri

Risque: le dock voit des fenetres via `ToplevelManager`, mais les actions utiles passent par des ids niri.

Mitigation: stocker les deux identifiants quand disponibles; utiliser `app_id` et `title` seulement pour resolution, pas comme identifiants stables.

### Layer-shell et fullscreen

Risque: un launcher sur `Top` disparait derriere une app fullscreen.

Mitigation: garder le launcher sur `Overlay` sous niri.

### Overview niri

Risque: le ring ou le wallpaper se comporte mal dans l'overview.

Mitigation: tester explicitement `Top`, `Overlay` et `Background`. Ne pas activer `place-within-backdrop` ni `blur true` global sur une surface fullscreen; pour Liquid Glass, preferer `BackgroundEffect.blurRegion` limite aux panneaux visibles et seulement `background-effect { xray false }` cote niri si le vrai contenu derriere les panneaux doit etre floute.

### Config utilisateur

Risque: Kama Shell modifie trop de fichiers geres par l'utilisateur.

Mitigation: fournir des exemples et des includes; ne pas ecrire automatiquement `~/.config/niri/config.kdl` sauf commande explicite.

### Xwayland

Risque: apps X11 ou jeux absents du dock ou avec metadata incomplete.

Mitigation: tester `xwayland-satellite`, garder les heuristiques `DesktopEntries`, documenter les limites.

## Matrice de verification

Minimum avant de declarer niri supporte:

- demarrage depuis display manager;
- demarrage depuis TTY si supporte;
- hot reload Quickshell;
- multi-ecran avec `Quickshell.screens`;
- ring visible sur chaque ecran;
- launcher au-dessus d'une fenetre fullscreen;
- focus clavier dans le launcher;
- fermeture launcher par clic exterieur et Escape;
- wallpaper rendu sur chaque ecran;
- blur niri ou rendu translucide sans fallback compositeur externe;
- dock pinned au premier chargement;
- dock running avec apps Wayland;
- dock running avec apps Xwayland;
- activation fenetre depuis dock;
- lancement app depuis dock;
- changement de workspace niri sans desynchronisation;
- overview niri;
- screenshot region/fenetre/ecran;
- sleep/lock/idle si documentes;
- portail screencast;
- reload ou restart sans scripts KWin.
- `rg -i "kwin|krunner|kwriteconfig|org.kde.KWin"` ne montre plus que de l'historique documente ou des notes de suppression, pas de chemin executable.

## Ordre recommande de PR

1. Documentation, detection backend et verrou anti-KWin/KRunner.
2. Session niri minimale et exemple `config.kdl`.
3. Suppression du fallback KRunner/KWin hors de `DockState`.
4. Backend fenetres niri ou validation `ToplevelManager` sous niri.
5. Workspaces niri.
6. Layer rules et effets visuels.
7. Packaging.
8. Retrait complet des fichiers KWin.

## Definition of done

La migration est terminee quand:

- niri est la session documentee par defaut;
- le launcher ne depend plus de scripts KWin;
- le dock ne depend plus de KRunner;
- les effets visuels sont configures via niri layer rules ou via `BackgroundEffect`;
- le packaging installe une session niri fonctionnelle;
- la documentation utilisateur explique les dependances, la config niri et le rollback;
- KWin, KRunner et `kwriteconfig6` ne sont plus presents dans les chemins supportes.

## References

- niri IPC: https://niri-wm.github.io/niri/IPC.html
- niri getting started: https://niri-wm.github.io/niri/Getting-Started.html
- niri config loading: https://niri-wm.github.io/niri/Configuration%3A-Introduction.html
- niri key bindings: https://niri-wm.github.io/niri/Configuration%3A-Key-Bindings.html
- niri layer-shell components: https://niri-wm.github.io/niri/Layer%E2%80%90Shell-Components.html
- niri layer rules: https://niri-wm.github.io/niri/Configuration%3A-Layer-Rules.html
- niri window effects: https://niri-wm.github.io/niri/Window-Effects.html
- niri integration notes: https://niri-wm.github.io/niri/Integrating-niri.html
- Quickshell `WlrLayershell`: https://quickshell.org/docs/master/types/Quickshell.Wayland/WlrLayershell/
- Quickshell `ToplevelManager`: https://quickshell.org/docs/master/types/Quickshell.Wayland/ToplevelManager/
