# TECH.md — Architecture technique de Kama Shell

Document de référence pour Claude. Lire ce fichier avant toute tâche de
développement, à la place d'un rescan complet du projet. Mettre à jour ici les
sections qui changent: tout ajout/renommage/déplacement de composant, singleton,
namespace layer-shell, clé de configuration ou helper doit être reporté dans la
même PR.

Sources d'autorité, dans l'ordre:

1. `AGENTS.md` — règles de contribution non négociables (Quickshell, niri,
   layer-shell, dock, launcher, documentation, vérification). Doit prévaloir
   sur ce document en cas de désaccord.
2. `docs/LESSONS.md` — pièges confirmés en session réelle. Lire avant de
   modifier QML/niri/layer-shell/dock/launcher/ring/icônes/processus/IO.
3. `docs/TECH.md` (ce fichier) — vue technique générale et carte du code.
4. `docs/DEBT.md`, `docs/PERFORMANCE.md` — état des dettes et plan perf en
   cours sur le ring.

---

## 1. Vue d'ensemble

Kama Shell est un shell Quickshell (Qt6 / QML) autonome lancé dans une session
[niri](https://github.com/YaLTeR/niri). Toutes les fenêtres du shell sont des
`PanelWindow` `WlrLayershell`, jamais des fenêtres `xdg-toplevel`.

Pile technique:

| Couche | Choix |
|---|---|
| Compositeur cible | niri (Wayland, layer-shell). KWin/KRunner retirés. |
| Runtime shell | Quickshell (`quickshell-git`) |
| Toolkit UI | QtQuick 2 / Qt6 |
| Forme du ring | `QtQuick.Shapes` (`Shape.CurveRenderer`, `PathSvg`) |
| Effets | `QtQuick.Effects` (`MultiEffect`, `RectangularShadow`) + `BackgroundEffect.blurRegion` (Quickshell ↔ niri) |
| Services système | `Quickshell.Services.{Pipewire,UPower,Networking,SystemTray}`, `DesktopEntries`, `ToplevelManager` |
| Scripting | JS QML uniquement |
| Config utilisateur | INI maison (`~/.config/kama-shell/kama.conf`) |
| Intégration niri | `niri msg --json` (event stream long-running + queries ponctuelles), layer-rules |

Dépendances runtime (PKGBUILD): `layer-shell-qt`, `niri`, `quickshell-git`,
`xwayland-satellite`. Helpers externes utilisés: `wpctl`, `brightnessctl`,
`loginctl`, `systemctl`, `python3`, `sh`, `find`, `niri`.

Point d'entrée: `src/shell.qml` (et non `shell.qml` à la racine).

```
ShellRoot {
    WallpaperWindow {}     // PanelWindow Background, multi-écran
    Ring {}                // PanelWindow Top, multi-écran (panneau principal)
    TrayMenuOverlay {}     // PanelWindow Overlay, menus QML du SystemTray
    SessionActionsOverlay {} // PanelWindow Overlay, actions session depuis le dock
    AppLauncherOverlay {}  // PanelWindow Overlay, focus clavier exclusif
    SettingsOverlay {}     // PanelWindow Overlay, panel paramètres, focus clavier exclusif
    OsdOverlay {}          // PanelWindow Overlay, passe-clic
    KamaShellIpc {}        // IpcHandler target "kama-shell"
}
```

Le pragma `//@ pragma IconTheme Yaru-red-dark` au début de `shell.qml` force
le thème d'icônes Qt (voir `docs/LESSONS.md`).

---

## 2. Cartographie du dépôt

```
src/
├── shell.qml                          Point d'entrée Quickshell
├── RingPathSelfTest.qml               Test offscreen du modèle géométrique
├── components/                        Primitives visuelles et fenêtres
├── ipc/KamaShellIpc.qml               IpcHandler target "kama-shell"
├── state/                             Singletons (état global, config, IPC)
└── assets/icons/{fluent,status}/      SVG Fluent UI System (MIT) embarqués
                                         pour indicateurs, dock et paramètres

config/
├── kama.conf.example                  Exemple de config utilisateur INI
└── niri/{config.kdl, config.kdl.example, binds.kdl, binds.dev.kdl}

scripts/
├── update-kama-config.py              Écriture atomique des clés kama.conf
└── check-qml-asset-urls.py            Lint: assets relatifs sans Qt.resolvedUrl

sessions/                              Sessions Wayland .desktop + wrappers
docs/                                  AGENTS source de vérité, LESSONS, DEBT, PERF, TECH
PKGBUILD, Makefile, run.sh             Empaquetage Arch, lint/test, runner local
qmldir                                 module KamaShell (vide pour l'instant)
```

`pkg/` est l'output de `makepkg` et n'est pas source de vérité — ne pas y
modifier de fichiers.

---

## 3. Fenêtres et couches Wayland

Toutes les fenêtres utilisent `WlrLayershell` et un namespace dédié. Chaque
namespace doit avoir une `layer-rule` côté niri si la surface utilise
`BackgroundEffect.blurRegion`, avec `background-effect { xray false }`, faute
de quoi niri ne floute que le wallpaper (cf. `docs/LESSONS.md`).

| Composant QML | Namespace layer-shell | Layer | Ancrage | Focus clavier | Exclusion |
|---|---|---|---|---|---|
| `WallpaperWindow` | `kama-shell-wallpaper` | `Background` | 4 côtés | `None` | `Ignore` |
| `Ring` | `kama-shell-ring` | `Top` | 4 côtés | défaut | défaut |
| `AppLauncherOverlay` | `kama-shell-launcher` | `Overlay` | 4 côtés | `Exclusive` quand visible | défaut |
| `SettingsOverlay` | `kama-shell-settings` | `Overlay` | 4 côtés | `Exclusive` quand visible | défaut |
| `TrayMenuOverlay` | `kama-shell-tray-menu` | `Overlay` | 4 côtés | `OnDemand` quand visible | défaut |
| `SessionActionsOverlay` | `kama-shell-session-actions` | `Overlay` | 4 côtés | `OnDemand` quand visible | défaut |
| `OsdOverlay` | `kama-shell-osd` | `Overlay` | 4 côtés | `None` | `Ignore` |

Le pattern multi-écran est systématiquement `Variants { model: Quickshell.screens }`
avec `required property var modelData` dans le delegate, comme prescrit par
`AGENTS.md`.

Les surfaces qui utilisent `BackgroundEffect.blurRegion`:

- `Ring` fournit une `RingBlurRegion` calculée à partir des segments CPU
  produits par `RingPath.buildInnerSegments`. **Ne jamais** approximer cette
  région par des rectangles ni ajouter `blur true` côté niri. Le ring est sur
  `WlrLayer.Top` pour rester sous les fenêtres fullscreen niri, et désactive
  aussi son mask et son blur quand `NiriWorkspaceState` détecte un état
  fullscreen explicite sur l'output actif.
- `AppLauncherOverlay`, `SettingsOverlay`, `TrayMenuOverlay`,
  `SessionActionsOverlay`, `OsdOverlay`
  exposent une `Region` rectangulaire arrondie calée sur la position de leur
  panel; chaque évolution doit appeler `region.changed()` via `Qt.callLater`
  quand x/y/w/h changent.
- `SettingsOverlay` définit aussi un `mask` d'input explicite: région vide
  quand le panel est fermé, plein écran quand il est ouvert. Les clics de
  fermeture sont portés par les quatre zones de scrim autour du panel, pas par
  une `MouseArea` plein écran placée sous le panel.

Le `Ring` est passe-clic en dehors de ses zones interactives grâce à
`RingRegions`: la région totale est la fenêtre moins la silhouette intérieure,
augmentée des zones de contenu (`dockContentItem`, `dockHoverItem`,
`homePanelItem`, `statusNotchItem`). `OsdOverlay` est entièrement passe-clic
(`mask: Region {}`).

---

## 4. Ring — modèle géométrique et rendu

Le ring est la structure visuelle centrale du shell: un cadre arrondi avec
une notch horloge en haut au centre, une notch d'indicateurs système en haut
à droite, un dock en bas et un panel Maison sur la droite. Le dock garde sa
petite bosse en état compact puis devient un tiroir rectangulaire à coins hauts
arrondis en état ouvert; le panel Maison garde sa petite bosse en état compact,
puis devient un tiroir rectangulaire à coins gauches arrondis en état ouvert.

### 4.1 Pipeline du ring (à connaître par coeur)

```
ExpandableEdgeWidget / HomePanel  ──revealProgress──▶  RingPanels
                                                          │
                                                          ▼
                                                    RingSlotModel       (modèle géométrique)
                                                          │
                                                ringGeometry { frame, slots{clock,status,dock,home} }
                                                          │
              ┌──────────────────────────────┬────────────┴──────────────┐
              ▼                              ▼                           ▼
       RingPath (singleton)         RingRegions (mask)         RingBlurRegion (BackgroundEffect)
              │                              │                           │
      buildSvgPath ────▶ RingSilhouettePath  │                  buildInnerSegments
              │                              │                           │
              ▼                              ▼                           ▼
       RingShapeSurface (visible)   InnerCutout + content      Spans pixellisés
                                    items du PanelWindow
```

### 4.2 Fichiers clés

- `src/components/Ring.qml` — `PanelWindow` multi-écran, branche
  `BackgroundEffect.blurRegion` sur `RingBlurRegion`, monte `RingPanels`,
  `RingSurfaceRenderer`, et `mask: RingRegions`.
- `src/components/RingPanels.qml` — instancie `RingSlotModel` (alimenté par
  les `revealProgress` du dock et du panel maison), ainsi que les items
  visibles (`DateTimeNotch`, `StatusNotch`, `HomePanel`, `HouseIcon` compact,
  `ExpandableEdgeWidget` qui héberge `AppDock`). Expose des alias vers les
  items interactifs pour le mask.
- `src/components/RingSlotModel.qml` — `QtObject` purement calculé. Reçoit
  les dimensions de fenêtre et les progressions de reveal, produit le modèle
  `ringGeometry` et toutes les métriques dérivées.
- `src/state/RingPath.qml` (`pragma Singleton`) — **source de vérité** des
  contours. Expose:
  - `normalizeGeometry(source, {inset})` — normalise un modèle (flat ou
    structuré) et applique un inset uniforme.
  - `flatGeometry(source, opts)` — projection à plat utilisée en interne.
  - `buildInnerSegments(geometry, opts)` — segments CPU (`line`, `cubic`,
    `arc`) consommés par `RingBlurRegion` pour le scanline.
  - `buildSvgPath(geometry, {inset, withOuterRectangle, outerWidth, outerHeight})`
    — chaîne SVG complète consommée par `RingSilhouettePath` via `PathSvg`.
  - `geometrySignature(geometry)` — clé stable pour invalider un cache.
  Les slots dock et Maison interpolent selon leur `revealProgress`: la bosse
  compacte reste inchangée au repos, puis devient un tiroir attaché au bord
  correspondant avec arêtes droites et coins extérieurs arrondis.
- `src/components/RingSilhouettePath.qml` — `ShapePath` réutilisable
  alimenté par `RingPath.buildSvgPath`. Supporte `inset`, `withOuterRectangle`
  (OddEvenFill), `outerWidth/Height`, et expose `fillColor`, `fillGradient`,
  `strokeColor`, `strokeWidth`.
- `src/components/RingShapeSurface.qml` — composition de `Shape`
  (`CurveRenderer`, `asynchronous: true`) qui empile remplissage gradient,
  bordure support, bordure principale et highlight intérieur, toujours via
  `RingSilhouettePath`.
- `src/components/RingSurfaceRenderer.qml` — wrapper de `RingShapeSurface`
  (un seul renderer aujourd'hui; l'ancien SDF a été retiré).
- `src/components/RingRegions.qml` — `Region` du `mask` du `PanelWindow`,
  intersection/subtract du rectangle plein avec la silhouette intérieure,
  puis ajout des items interactifs.
- `src/components/RingBlurRegion.qml` — produit la région exacte de blur.
  Algorithme: scanline pixel par pixel sur la hauteur, intersections avec
  les segments CPU (line/cubic/arc), compression verticale en spans
  `{x, y, width, height}`, recyclage d'un pool de `Region`. Instrumenté via
  `KAMA_TRACE_PERF=1`.
- `src/state/ShellGeometry.qml` — constantes de forme: `frameInset`,
  `cornerRadius`, dimensions du dock (rest/expanded), de la notch horloge,
  de la notch statut, du panel maison, calcul `homePanelTopFor(screenHeight)`.

### 4.3 Invariants à respecter

- Tout ce qui dessine ou masque la silhouette du ring **doit** passer par
  `RingPath`. Ne pas dupliquer `PathLine`/`PathCubic` dans un autre fichier.
- Ajouter une notch, un panneau ou une déformation = mettre à jour, dans la
  même PR: `RingSlotModel`, `RingPath` (segments + SVG), `RingRegions` (zones
  interactives) et la layer-rule niri si nécessaire.
- Conserver `RingShapeSurface` comme référence visuelle même si un nouveau
  renderer est introduit.
- Test offscreen: `src/RingPathSelfTest.qml` vérifie que `buildInnerSegments`
  et `buildSvgPath` produisent des sorties non vides, sans `NaN`, avec arc et
  cubic, et que la `geometrySignature` est stable. Lancé par `make test` via
  `QT_QPA_PLATFORM=offscreen quickshell -p src/RingPathSelfTest.qml`.

---

## 5. Singletons d'état (`src/state/`)

Tous les singletons sont déclarés avec `pragma Singleton` (`RingPath`,
`ShellConfig`, `ShellTheme`, `ShellGeometry`, `ClockState`,
`CompositorState`, `WallpaperState`, `DockState`, `DockIconResolver`,
`LauncherState`, `SettingsState`, `SessionActionsState`, `StatusNotchState`,
`OsdState`, `TrayMenuState`, `NiriIpc`, `NiriWorkspaceState`,
`NiriWindowBackend`).

### 5.1 Panel paramètres

- `SettingsState` — visibilité, section sélectionnée et écran cible du panel paramètres. Propriétés : `visible`, `selectedSection` (défaut `"appearance"`), `targetScreenName`. Méthodes : `show(screenName)`, `hide()`, `toggle(screenName)`. Helpers multi-écran identiques à `LauncherState` : `effectiveScreenName`, `firstScreenName`, `screenNameFor`, `hasScreenName`, `shouldShowOnScreen(screen)`.
- `SettingsContent` charge les sections dédiées depuis `src/components/settings/`:
  `AppearanceSection` pour le thème et la couleur du glow intérieur du ring,
  et `HomeSection` pour les réglages Home Assistant.

### 5.2 Config et thème

- `ShellConfig` — charge `~/.config/kama-shell/kama.conf` via `FileView`
  (`watchChanges: true`), parser INI maison avec sections (`[appearance]`,
  `[launcher]`, `[homeAssistant]`, `[dock]`). Expose `visualTheme`,
  `launcherShortcut`, `wallpaperPath`, `ringGlowColor`, `homeAssistantUrl`,
  `homeAssistantToken`, `dockPinnedApps`. Persistance des pinned apps via
  `savePinnedApps()` et du thème via `saveTheme(name)` → lance
  `python3 scripts/update-kama-config.py` avec sous-commandes `pinned-apps`
  ou `set-key`; `saveRingGlowColor(color)` persiste
  `appearance.ringGlowColor` après normalisation hex; `saveHomeAssistantConfig(url, token)`
  utilise `set-keys` pour écrire les deux clés Home Assistant dans la même
  opération atomique (`os.replace` + fsync directory). Thèmes supportés:
  `ffxiv`, `liquid-glass` (défaut).
- `ShellTheme` — design tokens (couleurs, opacités, rayons, polices). Bascule
  réactive entre `ffxiv` et `liquid-glass` sur changement de `ShellConfig.visualTheme`.
  Propriétés Liquid Glass spécifiques: `liquidBlurAmount/Max`, `liquidSaturation`,
  `liquidShadow*`. Tout composant doit lire les couleurs/rayons ici, jamais en
  dur.
- `ShellGeometry` — constantes de layout (frameInset, cornerRadius, tailles
  dock/notches/panel maison). Calcul `homePanelTopFor(screenHeight)`.
- `WallpaperState` — `path` (file://) ou couleur de fallback, alimenté par
  `ShellConfig.wallpaperPath`. Consommé par `WallpaperWindow` et par le
  backdrop local de `LiquidGlassSurface`.
- `ClockState` — `SystemClock` (précision Minutes), formate en français
  "weekday day month - HH:MM".

### 5.2 Compositeur et IPC niri

- `CompositorState` — détecte le backend (`niri` / `generic-wlr` / `unknown`)
  en lisant `KAMA_COMPOSITOR`, `NIRI_SOCKET`, `XDG_CURRENT_DESKTOP`,
  `XDG_SESSION_DESKTOP`. Expose `hasNativeToplevels`, `hasNiriIpc`,
  `hasLayerRules`, `supportsBackgroundEffect`. **Ne jamais** lire ces variables
  d'environnement ailleurs (cf. `AGENTS.md`).
- `NiriIpc` — wrappe `niri msg --json`. Deux modes:
  - `query(args, callback)` — création/destruction d'un `Process` éphémère
    avec `StdioCollector` (pattern à durée de vie courte; pas d'accumulation
    cross-run, cf. `docs/LESSONS.md`).
  - `startEventStream()` — `Process` long-running sur `niri msg --json event-stream`,
    consommé via `SplitParser` ligne par ligne. Redémarrage exponentiel via
    `eventStreamRestartTimer` plafonné à 5 s. Émet `eventReceived(event)`.
- `NiriWindowBackend` — source unique des fenêtres sous niri. Bootstrap via
  `query(["windows"])`, puis suit les events `WindowsChanged`,
  `WindowOpenedOrChanged`, `WindowClosed`, `WindowFocusChanged`. Normalise
  chaque fenêtre vers une forme compatible `ToplevelManager` (champs
  `appId`, `desktopId`, `iconName`, `title`, `activated`, `workspaceId`,
  `isFloating`, `isFullscreen`, `layout`, méthode `activate()`). `layout`
  conserve les tailles `window_size`/`tile_size` et l'offset niri pour les
  usages fenêtre futurs, mais ne doit pas être utilisé seul comme signal
  fullscreen. Signature stable pour éviter les rebuilds redondants.
- `NiriWorkspaceState` — état des outputs et workspaces via `niri msg`
  ponctuels, maintenu à jour par l'event stream niri. Expose
  `fullscreenOutputNames`, `focusedOutputHasFullscreen`,
  `hasFullscreenOnScreen(screen)`, `focusWorkspaceUp/Down`, `toggleOverview`,
  `focusWindowById`.

### 5.3 Dock

- `DockState` — orchestre la liste rendue par `AppDock`. Agrège pinned
  (`ShellConfig.dockPinnedApps`) et fenêtres ouvertes
  (`NiriWindowBackend.windows` si niri, sinon `ToplevelManager.toplevels`).
  Conserve un état `launchingApps[desktopId] = timestamp` purgé après 15 s
  ou quand l'app apparaît dans les toplevels. Signature stable
  (`signatureForItems`) pour ne notifier que les changements réels. Ordre:
  pinned → séparateur conditionnel → running non pinned. Une app pinned
  lancée reste un seul item enrichi (`isRunning`, `isActive`, `windowCount`,
  `windows`). Méthodes publiques: `activateItem`, `pinItem`, `unpinItem`,
  `trackLaunch`, `canChangePinState`.
- `DockIconResolver` — résolution asynchrone des icônes. Essaie d'abord
  `Quickshell.iconPath(name, true)`, puis fallback `find` dans
  `~/.local/share/icons`, `~/.icons`, `/usr/share/icons`, `/usr/share/pixmaps`.
  Cache des résultats; émet `iconLookupCacheChanged()` pour redéclencher un
  `DockState.queueRebuild()`. Pattern à respecter: créer un `Process` éphémère
  avec `Qt.createQmlObject` puis `destroy()` après collecte (cf. lesson sur
  `StdioCollector`).

### 5.4 Launcher

- `LauncherState` — visibilité, query, sélection, screen cible. Filtre
  `DesktopEntries.applications` via `filteredApplications(applications, query)`
  avec scoring (matchs exacts, préfixe, mot, sous-chaîne, genericName,
  keywords, id). Normalisation Unicode NFD. Helpers d'icônes / labels via
  `entryName`, `entryInitial`, `iconSourceFor`. `launchEntry(entry)` enregistre
  l'app dans `DockState.launchingApps`, exécute `entry.execute()`, masque.

### 5.5 Home Assistant

- `HomeAssistantState` — singleton de données domotiques. Consomme `ShellConfig.homeAssistantUrl`
  et `ShellConfig.homeAssistantToken`. Requêtes HTTP via `XMLHttpRequest` natif QML (pas de
  `Process` / curl).
  - **`refresh()`** — envoie un `POST /api/template` avec un template Jinja2 qui retourne un tableau
    JSON de pièces (areas HA filtrées à celles qui ont au moins une entité `light.*`, `cover.*`
    ou `climate.*`). Utilise `state_attr()` et le test `is_state` (plus fiables que `map('states')`).
  - **`toggleLights(areaId, currentlyOn)`** — `POST /api/services/light/turn_on|turn_off`
    avec `{ area_id }`. Mise à jour optimiste locale + refresh différé 1.5 s.
  - **`toggleCover(areaId, entityId, currentPosition)`** — `open_cover` / `close_cover` selon
    position courante. Mise à jour optimiste + refresh différé.
  - **`adjustTargetTemperature(areaId, entityId, delta)`** — `POST /api/services/climate/set_temperature`
    avec `{ entity_id, temperature }`. Incrément ±0.5°C, borné [10–30], arrondi à 0.5°. Mise à
    jour optimiste + refresh différé.
  - Auto-refresh toutes les 30 s via `Timer`. Refresh immédiat si `ShellConfig.homeAssistantUrl`
    ou `homeAssistantToken` change.
  - Propriétés exposées: `rooms` (JS Array), `loading`, `error`, `connected`, `isConfigured`.
  - Le champ `rooms[i]` contient: `id`, `name`, `lightIds[]`, `lightsOnCount`, `lightsTotal`,
    `lightsOn`, `coverIds[]`, `coverPosition` (0–100 ou -1), `climateIds[]`, `temperature`,
    `targetTemperature`.

### 5.6 Status notch et OSD

- `StatusNotchState` — agrégateur multi-services:
  - `SystemTray.items.values` (tray items applicatifs)
  - `Pipewire.defaultAudioSink` (typé `PwNode`, observé via `PwObjectTracker`),
    indicateur volume / mute calculé sur volume linéaire (cf. lesson)
  - `Networking.devices.values` (wifi vs ethernet)
  - `UPower.displayDevice` (laptop only, `percentage * 100` cf. lesson)
  - `/proc/stat` via `FileView` toutes les 2 s pour le CPU load
  - GPU load toutes les 2 s via le provider disponible (DRM sysfs
    `gpu_busy_percent`, `intel_gpu_top` si autorisé, ou helper vendor
    installé; `--%` si aucune source exploitable n'est exposée)
  - Calcule `statusNotchImplicitWidth` qui contraint la largeur du slot dans
    `RingSlotModel`.
- `OsdState` — kind (None/Volume/Brightness), level (0..1), muted, visible.
  Auto-masquage 2.5 s via `Timer`. Observe `StatusNotchState.audioVolume/Muted`
  pour déclencher l'OSD volume. `brightnessUp/Down` lance `brightnessctl -m
  set 5%±` et parse le CSV de sortie via `SplitParser`. Le flag `_ready`
  empêche le déclenchement au boot avant que `Pipewire` ait stabilisé.
- `TrayMenuState` — état du menu QML qui remplace les `QMenu` natifs (les
  menus natifs Qt deviennent des `xdg-toplevel` sous niri/layer-shell, cf.
  lesson). Expose `menu`, `screenName`, `anchorRect`, `visible`.
- `SessionActionsState` — état du popup d'actions session ouvert depuis le
  bouton du dock. Expose `visible`, `targetScreenName`, `anchorRect`,
  `currentAction`, `busy`, `canLogout`; lance `loginctl terminate-session`
  pour `Déconnexion`, `systemctl --no-ask-password reboot` pour
  `Redémarrer` et `systemctl --no-ask-password poweroff` pour `Éteindre`.

---

## 6. IPC interne (`kama-shell`)

`src/ipc/KamaShellIpc.qml` enregistre un `IpcHandler { target: "kama-shell" }`
avec ces méthodes:

| Méthode | Effet |
|---|---|
| `toggleLauncher()` | `LauncherState.toggle("")` |
| `showLauncher()` | `LauncherState.show("")` |
| `hideLauncher()` | `LauncherState.hide()` |
| `brightnessUp()` | `OsdState.brightnessUp()` |
| `brightnessDown()` | `OsdState.brightnessDown()` |
| `toggleSettings()` | `SettingsState.toggle("")` |
| `showSettings()` | `SettingsState.show("")` |
| `hideSettings()` | `SettingsState.hide()` |

Appelé depuis un bind niri:

```
qs ipc --path src/shell.qml --any-display call kama-shell toggleLauncher
qs ipc --path src/shell.qml --any-display call kama-shell toggleSettings
qs ipc --path /usr/share/kama-shell/src/shell.qml --any-display call kama-shell brightnessUp
```

Important: `qmllint` 1.0 ne parse pas les signatures IPC typées du fichier,
le Makefile l'exclut explicitement de la liste lintée
(`! -path 'src/ipc/KamaShellIpc.qml'`).

---

## 7. Surfaces thémables et effets

- `ThemedPanelSurface` — surface racine des panels overlay (launcher, tray
  menu, OSD). En thème `liquid-glass` instancie `LiquidGlassSurface`; en
  `ffxiv` produit un empilement de rectangles arrondis avec gradient/border.
  Propriété `compositorBlurActive` indique si le blur est déjà fourni par
  `BackgroundEffect.blurRegion` (auquel cas le backdrop local est désactivé).
- `LiquidGlassSurface` — backdrop local optionnel (`useLocalBackdrop`)
  pour les contextes sans blur compositeur: `ShaderEffectSource` du wallpaper,
  `MultiEffect` avec blur/saturation/brightness, masque rond via
  `MultiEffect.maskSource`, `RectangularShadow` portée par la surface. Reste
  cohérent avec les tokens `liquidBlurMax`, `liquidBlurAmount`,
  `liquidSaturation`, `liquidBrightness`, `liquidShadowBlur`,
  `liquidShadowOffsetY`, `liquidShadowAlpha` de `ShellTheme`.

URLs d'assets: toujours `Qt.resolvedUrl("../assets/...")`. Le linter
`scripts/check-qml-asset-urls.py` échoue si une string relative `"../assets/"`
apparaît sans `Qt.resolvedUrl(`. Exécuté par `make test`.

---

## 8. Configuration utilisateur

`~/.config/kama-shell/kama.conf` (format INI). Exemple
`config/kama.conf.example`. Toute évolution d'une clé doit être reflétée dans
cet exemple, dans la même PR.

| Clé | Type | Valeur défaut | Effet |
|---|---|---|---|
| `appearance.theme` | string | `liquid-glass` | Thème visuel. `ffxiv` ou `liquid-glass`. Synonymes acceptés: `liquid`, `current`, `default`. |
| `appearance.ringGlowColor` | hex color | `#46ff96` | Couleur du glow intérieur de la bordure du ring. Formats acceptés: `#rrggbb`, `rrggbb`, `#rgb`, `rgb`. |
| `appearance.wallpaper` | string | vide | Chemin du wallpaper rendu par Kama Shell. `~/...` accepté. Désactiver le wallpaper du DE pour éviter le double rendu. |
| `launcher.shortcut` | string | `Meta` (alias `Mod+D` documentaire) | Purement informatif. Kama Shell n'enregistre pas de raccourci global; aligner avec `config/niri/binds.kdl` ou le bind utilisateur. |
| `homeAssistant.url` | string | vide | URL de l'instance Home Assistant utilisée par le panel Maison. Normalisée en supprimant les `/` finaux. |
| `homeAssistant.token` | string | vide | Token d'accès longue durée Home Assistant utilisé pour l'API Maison. |
| `dock.pinnedApps` | list | `zen.desktop\|Z, org.gnome.Console.desktop\|T, org.gnome.Nautilus.desktop\|N, steam.desktop\|S` | Apps épinglées, format `desktopId\|fallbackLabel`. Modifié à chaud via `DockState.pinItem/unpinItem` → `update-kama-config.py`. |

Persistance des pinned apps: `ShellConfig.savePinnedApps` instancie un
`ConfigSaveProcess` (component interne) qui lance
`python3 $shellDir/../scripts/update-kama-config.py pinned-apps CONFIG_PATH VALUE`.
Le script garde l'ordre des sections existantes et insère `[dock]` si absent.
La page paramètres Maison persiste `homeAssistant.url` et
`homeAssistant.token` via la sous-commande `set-keys`, qui applique plusieurs
clés dans une seule écriture atomique.

---

## 9. Intégration niri

### 9.1 Layer rules

Tout namespace `kama-shell-*` qui utilise `BackgroundEffect.blurRegion`
doit avoir, dans `config/niri/config.kdl` ET `config/niri/config.kdl.example`:

```
layer-rule {
    match namespace="^kama-shell-<name>$"
    background-effect { xray false }
}
```

Sans `xray false`, niri ne floute que le wallpaper et pas les fenêtres
derrière (cf. `docs/LESSONS.md`). Pour le ring, ne **pas** ajouter
`blur true` côté niri: la région exacte est fournie par QML.

Le namespace de chaque nouvelle surface doit aussi être documenté dans le
commentaire de `config.kdl.example`.

### 9.2 Binds

- `config/niri/binds.kdl` — binds pour l'installation paquet (`/usr/bin/qs`,
  `/usr/share/kama-shell/src/shell.qml`). Inclus par la config niri
  utilisateur via `include optional=true "/usr/share/doc/kama-shell/niri-binds.kdl"`.
- `config/niri/binds.dev.kdl` — binds pour la session debug (`src/shell.qml`
  relatif au cwd). Inclus par `config/niri/config.kdl`.

Binds clés:

- `Mod+D` → `qs ipc … kama-shell toggleLauncher`
- `Mod+Comma` → `qs ipc … kama-shell toggleSettings`
- `XF86MonBrightnessUp/Down` → `qs ipc … brightnessUp/Down` (OSD piloté côté QML)
- `XF86AudioRaiseVolume/Lower/Mute` → `wpctl` direct (l'OSD volume est
  déclenché en observant `StatusNotchState.audioVolume/Muted`, pas par IPC)

### 9.3 Sessions

| Session | Fichiers | Quand l'utiliser |
|---|---|---|
| Production | `sessions/kama-shell-niri-session`, `start-kama-shell-niri-session`, `kama-shell-niri.desktop`, `config/niri/config.kdl.example` | Sortie paquet (PKGBUILD). Installable via `make install-session-niri`. |
| Debug | `sessions/kama-shell-niri-debug-session`, `start-kama-shell-niri-debug-session`, `kama-shell-niri-debug.desktop`, `config/niri/config.kdl` | Tree source, charge `quickshell -p src/shell.qml`, exporte `KAMA_DEV=1`, log dans `logs/kama-shell.log`. Installable via `make install-session-niri-debug`. Jamais empaquetée. |

Variables d'environnement exportées par les sessions:

- `KAMA_COMPOSITOR=niri` — verrouille la détection compositeur
- `XDG_CURRENT_DESKTOP=KamaShell:niri`
- `QT_QPA_PLATFORM=wayland`, `QT_WAYLAND_SHELL_INTEGRATION=layer-shell`
- `KAMA_DEV=1` (debug uniquement)
- `KAMA_QS_LOG_TIMES=1`, `KAMA_QS_VERBOSE=2`, `KAMA_RUN_LOG_FILE=…` (debug)

Override possible via `~/.config/kama-shell/session.conf` (et
`debug-session.conf` pour la debug). Voir `sessions/session.conf.example`
pour les variables disponibles (`KAMA_QS_*`, `KAMA_SESSION_PATH`,
`KAMA_XKB_*`).

`run.sh` couvre aussi un mode "Hyprland imbriqué" pour développer depuis
une session GNOME (`KAMA_NESTED_HYPRLAND=1` ou détection automatique). Ce
mode reste un compromis: la cible officielle est niri.

---

## 10. Vérification, tests, packaging

Commandes (toujours via `rtk` selon les règles globales):

| Commande | Effet |
|---|---|
| `rtk make run` | Lance `./run.sh` (à utiliser depuis un compositeur Wayland) |
| `rtk make check` | `qmllint -I src` sur tous les QML sauf `KamaShellIpc.qml` |
| `rtk make test` | `check` + `bash -n` sur les scripts shell + `python -m py_compile` + `check-qml-asset-urls.py` + `RingPathSelfTest` offscreen + `makepkg --printsrcinfo` vs `.SRCINFO` |
| `rtk make fmt` | `qmlformat -i` sur `src/` |
| `rtk make install-session-niri` | Installe la session paquet dans `/usr/share/wayland-sessions` |
| `rtk make install-session-niri-debug` | Installe la session debug (utilise le tree source) |

Limites connues (cf. `docs/LESSONS.md`):

- `qmllint` ne détecte ni les erreurs runtime liées à Wayland, ni les
  problèmes de timing `DesktopEntries`, ni les soucis de chemin
  `BackgroundEffect`.
- Le test offscreen `QT_QPA_PLATFORM=offscreen` valide la logique JS et la
  géométrie, pas les `PanelWindow`.
- Les logs Quickshell binaires (`log.qslog`) doivent être lus avec `strings`.

Packaging: `PKGBUILD` (Arch). `makepkg --printsrcinfo` doit rester identique
à `.SRCINFO` (vérifié par `make test`).

---

## 11. Conventions de code à respecter

Tirées de `AGENTS.md` et `docs/LESSONS.md`:

1. **Imports.** Pas de `root:/...`. Imports relatifs (`import "../state"`) ou
   imports de module Quickshell.
2. **Multi-écran.** `Variants { model: Quickshell.screens }` + `required
   property var modelData`. Ne pas référencer depuis un objet partagé un `id`
   déclaré à l'intérieur d'un composant `Variants`.
3. **État partagé.** Tout état réutilisé entre fenêtres → `pragma Singleton`.
   Pas de `Process` / `Timer` dupliqué par fenêtre.
4. **Sources système.** Privilégier les services natifs Quickshell
   (`SystemClock`, `Pipewire`, `UPower`, `Networking`, `SystemTray`,
   `DesktopEntries`, `ToplevelManager`) plutôt qu'un `Process` externe.
5. **niri IPC.** Toute requête niri passe par `NiriIpc`. Toujours.
6. **`PanelWindow.anchors`.** Déclarer explicitement les 4 ancres si tu veux
   couvrir l'écran. `exclusiveZone` n'est valide qu'avec 1 ou 3 ancres.
   `focusable: false` par défaut.
7. **Assets locaux.** `Qt.resolvedUrl("../assets/...")` — jamais une string
   concaténée.
8. **Composants `Variants` et items injectés.** Préférer `Item` à `QtObject`
   pour un delegate qui contient des `Connections`.
9. **Process / IO.** `StdioCollector` accumule entre runs — soit créer un
   process éphémère (`createObject` → `destroy()`), soit utiliser
   `SplitParser` (ligne par ligne, pas d'accumulation).
10. **Pipewire.** `PwNode.audio` est `isPropertyConstant`. Inclure
    `audioSink.ready` dans la condition `hasAudio`. Typer `audioSink` comme
    `PwNode` et non `var`. `volume` est un float linéaire 0..∞, pas un %.
11. **UPower.** `percentage` est en 0..1, multiplier par 100 pour comparer
    à des seuils %.
12. **Tray menus.** Toujours le pipeline QML (`TrayMenuOverlay` →
    `TrayMenuState` → `TrayMenuPanel`). Ne pas déléguer à `QMenu` natif.
13. **Comportements de reveal.** Pour tout panel intégré au ring,
    `revealProgress` pilote simultanément: contenu, cutout intérieur,
    outlines, fill du ring, opacité de l'icône compacte. Si une zone est
    interactive, l'ajouter au `mask` du `PanelWindow` du ring (sinon Wayland
    peut ne pas transmettre les events).
14. **Animations.** `NumberAnimation` courte + `OutCubic` plutôt que
    `SpringAnimation` (cf. `docs/PERFORMANCE.md` pour le contexte).

---

## 12. Points d'extension durables

Ce qui est conçu pour grandir:

- **`ExpandableEdgeWidget`** — primitive de widget rétractable réutilisable
  dans le ring. Toute future affordance bord-d'écran qui s'ouvre au survol
  doit passer par ce composant (et non recopier la logique du dock).
- **`RingPath`** — pour toute nouvelle déformation du ring (nouvelle notch,
  panneau latéral, etc.). Ajouter le segment dans `buildInnerSegments` et
  s'assurer que `buildSvgPath` le suit; étendre `flatGeometry` au besoin.
- **`ShellGeometry`** — toute constante de layout liée au ring/dock/panel.
- **`ShellTheme`** — tout token visuel (couleurs, rayons, polices, opacités).
- **`KamaShellIpc`** — toute action déclenchable par un bind niri ou un
  `qs ipc call`.
- **`NiriIpc`** — toute nouvelle interaction `niri msg --json`. Action ou
  query, pas un `Process` ad hoc.
- **`StatusNotchState`** — agréger un nouvel indicateur système ici plutôt
  que dans `StatusNotch.qml`.
- **`SettingsContent`** — zone de contenu du panel paramètres. Pour ajouter
  une section: ajouter l'entrée dans `SettingsMenu.sections`, créer un
  composant dédié dans `src/components/settings/`, le câbler dans le
  switch de `SettingsContent.sourceComponent`. Sections actuelles:
  `AppearanceSection`, `HomeSection`.

Ce qui doit rester simple/local:

- `HomePanel` et ses children (`HomeRoomRow`, `HomeDeviceControl`,
  `HouseIcon`) — UI du panel domotique. La logique réseau est dans
  `HomeAssistantState`; les composants d'affichage ne font que lire l'état
  et appeler les actions.
- `SessionActionButton` — bouton session du dock uniquement; ouvre
  `SessionActionsOverlay` au lieu d'exécuter directement une action système.

---

## 13. Pour mettre à jour ce fichier

Toute PR qui touche au moins l'un des points suivants doit aussi modifier ce
document:

- Ajout, renommage ou suppression d'un singleton dans `src/state/`
- Ajout, renommage ou suppression d'une fenêtre `PanelWindow` ou d'un
  namespace layer-shell
- Modification d'une layer-rule niri
- Ajout d'une méthode publique sur l'`IpcHandler` `kama-shell`
- Ajout d'une clé dans `kama.conf` ou changement de son comportement
- Modification de la pipeline géométrique du ring
  (`RingPath`/`RingSlotModel`/`RingRegions`/`RingBlurRegion`/`RingShapeSurface`)
- Ajout d'une nouvelle source d'icônes ou d'assets embarqués

Si le changement contredit un point de `AGENTS.md` ou de `docs/LESSONS.md`,
mettre d'abord ces fichiers à jour: ils sont la source de vérité.
