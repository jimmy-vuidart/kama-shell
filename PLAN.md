# PLAN.md — Kama-Shell (Quickshell / Qt6 / QML)

> Plan de construction du shell Kama-Shell sur **Quickshell / Qt6 / QML / GLSL**.
> Worktree : branche `quickshell-v3` dans `glass-shell-qs/`.

---

## 0. Principes directeurs

1. **Projet runnable à chaque phase.** Pas de phase qui laisse le shell non-lançable plus d'une journée.
2. **Une phase = un commit ou une série cohérente.** Le titre de phase devient le sujet de commit.
3. **Pas de spawn synchrone dans la main loop.** Tous les subprocess sont asynchrones (`Quickshell.Io.Process`), toutes les lectures fichier sont non-bloquantes (`FileView`). Un seul spawn sync à 120 Hz suffit à casser le budget d'une frame.
4. **Tout visuel passe par des design tokens centralisés.** Aucun `color: "#…"` ou `radius: 12` hardcodé dans les composants hors `theme/`.
5. **Debug overlay hors du surface de prod.** Un flag `KAMA_DEV=1` conditionne l'overlay et ses input-regions — le mode prod n'en contient aucune trace.
6. **Pas de parser string-search sur du JSON ou structuré.** Toujours `JSON.parse` ou l'API native du format.
7. **Aucune dimension hardcodée pour une résolution spécifique.** Chaque valeur dépendante de l'écran se calcule depuis `Quickshell.screens[i]` ou la config.

---

## 1. Stack cible

| Couche | Choix | Pourquoi |
|---|---|---|
| Runtime shell | **Quickshell** (AUR `quickshell-git`) | layer-shell natif, scene graph GPU, `ShaderEffect`, WebSocket, DBus QML |
| UI | QtQuick 2 / QML | déclaratif, animations first-class (`Behavior on`, `SpringAnimation`) |
| Custom rendering | `Shape` + `ShaderEffect` (GLSL ES) | frame polygonale + pulse perimeter |
| Scripting | JS QML (pas de TypeScript) | simplicité, pas de build step |
| Style tokens | QML Singletons (`pragma Singleton`) | typé via `readonly property` |
| Config | TOML dans `~/.config/kama-shell/config.toml` | parser TOML embarqué (ou JSON en fallback) |
| Secrets | `secret-tool` CLI via `Process` | HA token et autres, pas besoin de lib Qt supplémentaire |
| DBus | `Quickshell.Io` + `DBusObject` | Media player, portals et services desktop génériques |
| Subprocess | `Quickshell.Io.Process` | wpctl, brightnessctl, nmcli, upower (async) |
| Fichiers | `Quickshell.Io.FileView` | `/proc/stat`, `/sys/class/...` |
| WebSocket | `QtWebSockets` | Home Assistant |

---

## 2. Non-goals (explicites)

- **Pas de HDR.** Décision produit : dropped.
- **Pas de support Hyprland.** Cible = Niri par défaut, labwc en option de session légère.
- **Pas de dépendance à un compositor spécifique dans QML.** Le shell consomme les protocoles Wayland exposés par Quickshell; les raccourcis globaux restent dans la configuration du compositor.
- **Pas de dépendance à un environnement desktop complet.** Les services périphériques (portals, polkit, idle, lock) restent des composants explicites.
- **Pas de TypeScript.** JS QML suffit pour un shell de cette taille.

---

## 3. Jalons de validation

La construction suit trois jalons mesurables :

### Jalon A — Shell de base (fin Phase 7)

- [ ] Shell lançable via `./run.sh` (`quickshell -p shell.qml`)
- [ ] Frame 4 bandes layer-shell sur les 3 moniteurs, visuellement continue
- [ ] Pulse perimeter 120 Hz fluide sur le moniteur principal
- [ ] Sidebar avec 3 entrées, Header, Dock visibles
- [ ] Navigation Dashboard / Gaming / Dev via StackLayout
- [ ] Horloge temps réel dans le dock
- [ ] 7 sondes système asynchrones : CPU, RAM, batterie, réseau, wifi/bt, volume, luminosité
- [ ] Aucun `spawn_sync`, aucun parser string-search
- [ ] Frame et pulse répliqués sur les 3 moniteurs

### Jalon B — Shell intégré (fin Phase 11)

- [ ] Universes = workspaces ou univers logiques via IPC compositor, changement d'Universe modifie la teinte du pulse
- [ ] Settings panel overlay avec matrice widget × moniteur, persistance TOML
- [ ] HA token dans gnome-keyring
- [ ] Widget Home Assistant connecté en WebSocket, toggle fonctionnel sur une entité test

### Jalon C — Shell expressif (fin Phase 13)

- [ ] Dynamic Island morphant sur MPRIS / downloads / recording
- [x] Task dock hybride : pinned + running-not-pinned

État actuel du dock:

- intégré visuellement au bas du ring, avec une bosse centrale sculptée dans la géométrie du ring
- rendu séparé de l'état, via `src/components/AppDock.qml` + `src/state/DockState.qml`
- apps pinned et apps lancées agrégées via `DesktopEntries` et `ToplevelManager`
- résolution d'icônes basée sur `DesktopEntry.icon`, avec recherche dans les emplacements standards d'icônes si le thème Qt ne résout pas immédiatement

---

## 4. Phases

Chaque phase : **Objectif**, **Tâches atomiques**, **Definition of Done** (DoD), **Estimation**.

---

### Phase 0 — Bootstrap Quickshell (≈ 4 h) ✓

**Objectif.** `./run.sh` ouvre une fenêtre layer-shell vide en bas d'écran avec un rectangle coloré.

**Tâches.**
1. Installer : `paru -S quickshell-git qt6-base qt6-declarative qt6-wayland qt6-websockets libsecret brightnessctl upower networkmanager wireplumber`. ✓
2. Vérifier la version Quickshell (doit exposer `PanelWindow`, `Quickshell.Io`, `Quickshell.Wayland`). ✓
3. Créer `shell.qml` minimal : ✓
   ```qml
   import Quickshell
   import Quickshell.Wayland
   import QtQuick

   PanelWindow {
     anchors.bottom: true
     implicitHeight: 60
     Rectangle { anchors.fill: parent; color: "red" }
   }
   ```
4. Créer `qmldir` racine + structure de dossiers (voir §6). ✓
5. Script `run.sh` : `exec quickshell -p shell.qml "$@"`. ✓
6. `justfile` ou `Makefile` minimal : cibles `run`, `check`, `fmt`. ✓

**DoD.** `./run.sh` affiche un rectangle rouge en bas de l'écran principal. Fermeture Ctrl+C propre. ✓

---

### Phase 1 — Design tokens et primitives (≈ 8 h)

**Objectif.** Poser les Singletons de thème. Valeurs directement inlinées ci-dessous.

#### 1.1 Palette

```qml
// src/theme/Tokens.qml
pragma Singleton
import QtQuick

QtObject {
  // Backgrounds
  readonly property color bgDeep:         Qt.rgba(7/255,  16/255,  75/255, 0.92)
  readonly property color bgPanel:        Qt.rgba(28/255, 32/255, 109/255, 0.58)
  readonly property color bgPanelStrong:  Qt.rgba(48/255, 28/255, 117/255, 0.72)

  // Strokes
  readonly property color strokeSoft:     Qt.rgba(124/255, 153/255, 255/255, 0.28)
  readonly property color strokeBright:   Qt.rgba(111/255, 199/255, 255/255, 0.55)
  readonly property color strokeRim:      Qt.rgba(123/255, 150/255, 255/255, 0.34)

  // Text
  readonly property color textPrimary:    "#f6f7ff"
  readonly property color textSecondary:  Qt.rgba(232/255, 236/255, 255/255, 0.72)
  readonly property color textMuted:      Qt.rgba(237/255, 249/255, 255/255, 0.86)

  // Accents (Universe colors + misc)
  readonly property color accentBlue:     "#45a5ff"
  readonly property color accentViolet:   "#a55cff"
  readonly property color accentPink:     "#ff4da6"
  readonly property color accentOrange:   "#ff8a3d"
  readonly property color accentGreen:    "#73ffb7"

  // Radii
  readonly property int radiusXL: 34
  readonly property int radiusLG: 26
  readonly property int radiusMD: 20
  readonly property int radiusSM: 16

  // Fonts
  readonly property string fontFamily:     "JetBrainsMono Nerd Font, JetBrains Mono, sans-serif"
  readonly property string fontFamilyMono: "JetBrainsMono Nerd Font Mono, JetBrains Mono, monospace"
}
```

#### 1.2 Espacement

```qml
// src/theme/Spacing.qml
pragma Singleton
import QtQuick

QtObject {
  readonly property int s1: 10
  readonly property int s2: 16
  readonly property int s3: 22
  readonly property int s4: 28
}
```

#### 1.3 Motion

```qml
// src/theme/Motion.qml
pragma Singleton
import QtQuick

QtObject {
  readonly property int durFast:   180
  readonly property int durMedium: 260
  readonly property int durSlow:   420
  readonly property int easeOut:   Easing.OutCubic
  readonly property int easeBack:  Easing.OutBack
  readonly property int spring:    Easing.OutElastic
}
```

#### 1.4 Surface glass (mixin équivalent)

```qml
// src/primitives/GlassSurface.qml  (base des cartes)
import QtQuick
import "../theme"

Rectangle {
  border.width: 1
  border.color: Tokens.strokeRim
  gradient: Gradient {
    GradientStop { position: 0.0; color: Qt.rgba(31/255, 44/255, 125/255, 0.86) }
    GradientStop { position: 1.0; color: Qt.rgba(16/255, 20/255,  74/255, 0.84) }
  }
  // Shadow shell approximation via DropShadow (Qt5Compat.GraphicalEffects) ou MultiEffect Qt6
}
```

Shadow glass cible (à reproduire via `MultiEffect` ou `DropShadow`) :
- inset top : `rgba(255, 255, 255, 0.12)` 1 px
- outer : offset `y=22`, blur `70`, color `rgba(2, 8, 40, 0.42)`

#### 1.5 Primitives à implémenter

- `GlassCard.qml` — carte (padding 22, radius 30, border `strokeRim`, gradient + shadow)
- `GlassButton.qml`
- `GlassSlider.qml` — track `rgba(255, 255, 255, 0.08)`, fill `linear-gradient(90deg, accentBlue, accentViolet)`, min-height 8, radius 99
- `GlassToggle.qml`
- `SectionTitle.qml` — heading 28 px bold 800, subtitle secondary color, trailing pill 8×12 radius 999 `rgba(70, 86, 215, 0.18)`
- `StatusChip.qml` — padding 7×12, radius 999, font 11 px bold 700 ; variants `--blue` bg `rgba(55, 141, 255, 0.24)`, `--pink` bg `rgba(255, 77, 166, 0.2)`, `--violet` bg `rgba(165, 92, 255, 0.22)`
- `MetricPill.qml` — min-width 120, padding 16, radius `radiusMD`, bg `rgba(52, 65, 162, 0.82)`, border `rgba(107, 132, 255, 0.2)`, value 30 px bold 800
- `Showcase.qml` — page temporaire non montée en prod, affiche toutes les primitives.

**DoD.** `quickshell -p showcase.qml` affiche toutes les primitives, cohérentes avec la maquette. Aucune couleur littérale dans les primitives — tout vient de `Tokens`.

---

### Phase 2 — Frame à 4 côtés (≈ 10 h)

**Objectif.** 4 bandes layer-shell (top/right/bottom/left) visuellement continues sur le moniteur principal.

**Géométrie de référence (moniteur ultrawide 3440×1440).**

```qml
// src/frame/FrameGeometry.qml
pragma Singleton
import QtQuick

QtObject {
  // Épaisseurs de bande par défaut — redéfinissables par moniteur
  readonly property int thicknessUltrawide: 48
  readonly property int thicknessSide:      32

  // Tab glass top-center (Header)
  readonly property int topTabWidth:        260
  readonly property int topTabHeight:       54
  readonly property int topTabRise:         64
  readonly property int topTabInnerPadding: 22

  // Dock bottom-center
  readonly property int bottomDockWidth:    560
  readonly property int bottomDockHeight:   84

  // Insets du stage (padding intérieur pour que le contenu ne touche pas la frame)
  readonly property int contentInsetTop:    68
  readonly property int contentInsetRight:  28
  readonly property int contentInsetBottom: 104
  readonly property int contentInsetLeft:   76

  // Coins
  readonly property int cornerRadiusOuter:  26
  readonly property int cornerRadiusInner:  20
}
```

**Tâches.**
1. `src/frame/Frame.qml` : orchestrateur, instancie 4 `FrameEdge` (top / right / bottom / left).
2. `src/frame/FrameEdge.qml` : 1 `PanelWindow` ancré sur le(s) bord(s) correspondant(s), `implicitHeight`/`implicitWidth` = épaisseur.
3. Background glass : `Rectangle` avec le gradient + border issus des tokens, radius interne sur les coins (les 2 bandes adjacentes doivent masquer leur coin commun).
4. `exclusivity` réglée pour que les apps puissent occuper la zone centrale (tester avec `kitty --class test`).
5. Mode `KAMA_DEV=1` qui colorise chaque bande différemment pour vérifier l'alignement pixel-perfect.

**DoD.** Frame 4 côtés visible, coins cohérents, pas de gap visible entre les bandes. Une app ouverte s'affiche dans la zone centrale sans être masquée.

---

### Phase 3 — Pulse perimeter shader (≈ 8 h)

**Objectif.** Glow 1–2 px qui parcourt le périmètre des 4 bandes à 120 Hz. Vitesse pilotée par la charge CPU, couleur par l'Universe active.

**Tâches.**
1. Écrire `shaders/pulse.frag` (GLSL ES) avec uniforms :
   - `uniform float uProgress` — position le long du périmètre, 0..1
   - `uniform float uIntensity`
   - `uniform vec4  uColor`
   - `uniform vec4  uFrameRect` — bounds de la bande pour distance field
2. Approche recommandée : distance field calculé fragment-side sur l'inner edge de la bande ; le glow est `smoothstep(dist - halfWidth, dist + halfWidth, …) * gaussian(arcPos - progress)`.
3. `src/frame/PulseShader.qml` : `ShaderEffect` qui wrap le shader, exporte `progress`, `color`, `intensity`.
4. `src/PulseBus.qml` (Singleton) :
   - `property real progress: 0` piloté par un `NumberAnimation { from: 0; to: 1; loops: Animation.Infinite; duration: speedFromLoad }`
   - `property color tint: Tokens.accentViolet` (sera bindé à l'Universe active en Phase 8)
   - `property real cpuLoad01: 0` (phase 3 : mock via `Timer`, phase 6 : branché sur `Cpu`)
5. Chaque `FrameEdge` instancie son `PulseShader` et lit `PulseBus.progress` + `PulseBus.tint`.
6. Duration de `NumberAnimation` bindée à `1500 + (1 - PulseBus.cpuLoad01) * 1500` (rapide quand chargé, lent au repos) — ajuster par expérimentation.

**DoD.** Glow fluide 120 Hz visible sur le moniteur principal, traverse les 4 côtés sans discontinuité. Pas de chute FPS. Slider de debug (en mode DEV) pour faire varier `cpuLoad01` et `intensity`.

---

### Phase 4 — Layout components (≈ 6 h)

**Objectif.** Sidebar, Header, Dock visibles, statiques, sans logique métier.

**Dimensions de référence.**

| Zone | Propriété | Valeur |
|---|---|---|
| Sidebar | min-width | 116 |
| Sidebar rail | min-width | 108 |
| Sidebar rail | min-height | 380 |
| Sidebar rail | padding | 18 × 10 |
| Sidebar rail | radius | 24 |
| Sidebar item | padding | 14 × 8 |
| Sidebar item | radius | 18 |
| Sidebar item active | outline | `rgba(111, 199, 255, 0.42)` |
| Sidebar item active | background | `linear-gradient(180deg, rgba(123, 79, 255, 0.52), rgba(43, 96, 255, 0.32))` |
| Header bar | min-height | 64 |
| Header title | font-size | 16 bold 800 |
| Header title | letter-spacing | 1.8 px |
| Dock | min-height | 84 |
| Dock | min-width | 560 |
| Dock | padding | 16 × 24 × 14 |
| Dock | radius | 22 22 30 30 |
| Dock item | min-width | 72 |
| Dock item | padding | 14 × 8 |
| Dock item | radius | 18 |
| Dock item | background | `rgba(255, 255, 255, 0.22)` |

**Tâches.**
1. `src/components/Sidebar.qml` — `ColumnLayout` avec 3 entrées (voir Phase 5 pour la source de vérité des entrées). Entrée active lit `Navigation.currentSection`.
2. `src/components/Header.qml` — bandeau top-center, title zone avec placeholder "DASHBOARD / GAMING UNIVERSE / DEV UNIVERSE" (16 px bold, letter-spacing 1.8 px).
3. `src/components/Dock.qml` — bandeau bottom-center avec horloge temps réel (binding `Clock.time`) + placeholders icônes.

**DoD.** Sidebar affiche 3 entrées, clic modifie `Navigation.currentSection`. Header et Dock visibles avec horloge temps réel mise à jour toutes les secondes.

---

### Phase 5 — Navigation + stage (≈ 4 h)

**Objectif.** Fenêtre layer-shell BOTTOM ("stage") affiche un `StackLayout` piloté par `Navigation`.

**Sections à exposer (inlinées).**

```qml
// src/Navigation.qml
pragma Singleton
import QtQuick

QtObject {
  readonly property var sections: [
    { id: "dashboard", label: "Dashboard",       icon: "HOME" },
    { id: "gaming",    label: "Gaming Universe", icon: "GAME" },
    { id: "dev",       label: "Dev Universe",    icon: "DEV"  },
  ]
  property string currentSection: "dashboard"
  readonly property int sectionIndex: {
    for (var i = 0; i < sections.length; i++)
      if (sections[i].id === currentSection) return i
    return 0
  }
}
```

**Tâches.**
1. `Navigation.qml` Singleton (ci-dessus).
2. `src/stage/Stage.qml` — `PanelWindow` full-screen, `exclusivity: Ignore`, contient `StackLayout { currentIndex: Navigation.sectionIndex }`.
3. Écrans placeholder : `Dashboard.qml`, `Gaming.qml`, `Dev.qml`, chacun avec une `Label` centrée.
4. Sidebar câblée : clic → `Navigation.currentSection = sections[i].id`.

**DoD.** Clic sur une entrée sidebar change l'écran affiché. Transition basique (un simple changement d'index en phase 5 ; transitions riches en Phase 12).

---

### Phase 6 — Services système async (≈ 12 h)

**Objectif.** Toutes les sondes système sont asynchrones, exposées en QtObject Singletons.

**Intervalles et sources (inlinés).**

| Service | Intervalle | Source |
|---|---|---|
| `Cpu`        | 2 000 ms  | `/proc/stat` via `FileView`, deltas CPU time |
| `Ram`        | 5 000 ms  | `/proc/meminfo` via `FileView` |
| `Battery`    | 15 000 ms | `upower -e` + `upower -i <path>`, fallback `/sys/class/power_supply/BAT*` |
| `Network`    | 2 000 ms  | `nmcli -t -f DEVICE,STATE,CONNECTION device status`, débit via `/sys/class/net/<iface>/statistics/{rx,tx}_bytes` |
| `Wifi`       | 5 000 ms  | `nmcli radio wifi` |
| `Bluetooth`  | 8 000 ms  | `bluetoothctl show` (pas `rfkill --json`) |
| `Focus`      | 30 000 ms | DND status via DBus `org.freedesktop.Notifications` ou fallback mock |
| `Audio`      | 2 000 ms  | `wpctl get-volume @DEFAULT_AUDIO_SINK@` — conserver la valeur réelle sans clamp |
| `Brightness` | 5 000 ms  | `brightnessctl -m` |
| `Clock`      | 1 000 ms  | `Qt.formatDateTime(new Date())` |

**Principe commun.**
- Chaque service est un Singleton `QtObject`.
- Polling via `Timer { interval: …; repeat: true; running: true; onTriggered: poll() }`.
- Subprocess via `Process { running: false; command: […]; onExited: parse(stdout) }`.
- Exposer trois états : `status: "loading" | "ok" | "error"`, ne jamais crasher si la commande échoue.
- Valeurs numériques normalisées en `[0, 1]` quand applicable (`level01`, `usedRatio01`).

**Tâches.**
1. Implémenter chaque service dans `src/services/<Name>.qml` avec le Timer et le Process.
2. `src/services/qmldir` pour import propre.
3. Dashboard montre les 7 sondes principales (pas Focus/Clock/Network qui sont secondaires visuellement).
4. Brancher `PulseBus.cpuLoad01` sur `Cpu.usage01`.

**DoD.** Dashboard affiche les sondes, chaque valeur se met à jour, aucun freeze si on déconnecte le réseau ou retire la batterie (laptop). Aucun `spawn_sync`.

---

### Phase 7 — Multi-moniteur (≈ 6 h)

**Objectif.** Frame + pulse + chrome répliqués sur 3 moniteurs. Stage uniquement sur le moniteur principal.

**Config par moniteur (référence).**

| Moniteur | Résolution | Épaisseur frame | Widgets |
|---|---|---|---|
| Ultrawide principal | 3440×1440 @ 120 Hz VRR | 48 px | tous |
| Latéral 1 | 1920×1080 | 32 px | réduit (pas Home/Finance) |
| Latéral 2 | 1920×1080 | 32 px | réduit |

**Tâches.**
1. Passer `Frame` en `Variants { model: Quickshell.screens; delegate: Frame { screen: modelData } }`.
2. `src/MonitorConfig.qml` Singleton — map screenId → `{ thickness, widgets: […] }`.
3. Stage instancié uniquement sur `Quickshell.primaryScreen`.
4. `PulseBus` global (déjà en place depuis Phase 3) : tous les moniteurs partagent `progress`.
5. Tester unplug/replug : `Quickshell.screens` est réactif, `Variants` doit se régénérer sans crash.

**DoD.** 3 moniteurs ont chacun leur frame, le glow tourne partout. Unplug d'un latéral ne crashe pas. Replug réinstaure la frame.

---

### Phase 8 — Universes via IPC compositor (≈ 4 h)

**Objectif.** Mapper les workspaces ou univers logiques du compositor aux Universes. Universe Selector sidebar change l'univers actif via le mécanisme IPC disponible.

**Tâches.**
1. `src/services/Universes.qml` :
   - source Niri via `niri msg --json event-stream` si `KAMA_COMPOSITOR=niri`
   - fallback local si le compositor ne publie pas de workspaces exploitables
2. Expose `model` (ListModel `{id, name, icon}`), `currentId`, `setCurrent(id)`.
3. `src/components/UniverseSelector.qml` : ListView bindée à `Universes.model`, item actif = `currentId`.
4. Chaque Universe a une couleur d'accent dans `Config.universes[id].accent` (défauts : violet, blue, pink). `PulseBus.tint` bindé sur `Config.universes[Universes.currentId].accent`.
5. Documenter les limites labwc si l'IPC de workspace est insuffisant.

**DoD.** Changer d'univers change la couleur du pulse en temps réel. Sous Niri, le changement suit l'état publié par l'IPC du compositor.

---

### Phase 9 — Config TOML + Settings panel (≈ 10 h)

**Objectif.** Settings panel plein écran, matrice widget × monitor, persistance TOML.

**Tâches.**
1. `src/config/tomlParser.js` — parser TOML MIT (ou fallback JSON si rien de simple disponible).
2. `src/config/Config.qml` Singleton :
   - Charge `~/.config/kama-shell/config.toml` via `FileView`
   - Expose `config.widgets[name].enabled`, `config.widgets[name].monitors[id]`, `config.ha.baseUrl`, `config.universes`, etc.
   - Fallback sur `defaults` hardcodés si absent.
3. `src/settings/SettingsState.qml` Singleton — `property bool visible: false`.
4. `src/settings/SettingsPanel.qml` — `PanelWindow { anchors: all; exclusivity: Exclusive; visible: SettingsState.visible }`.
5. Grille dynamique : `ListView` sur `Config.widgetRegistry`, chaque ligne = un `Repeater` sur `Quickshell.screens` avec un toggle par cellule.
6. Bouton Save → sérialiser → écrire `config.toml`.
7. Ouverture : gear icon dans le Header (pas de keybind global côté shell).

**Arborescence config cible.**

```toml
[widgets.pulseperimeter]
enabled = true
monitors = { "DP-1" = true, "HDMI-A-1" = true, "HDMI-A-2" = true }

[widgets.home]
enabled = true
monitors = { "DP-1" = true, "HDMI-A-1" = false, "HDMI-A-2" = false }
entities = ["light.salon", "switch.bureau"]

[ha]
baseUrl = "http://homeassistant.local:8123"
# token stocké dans gnome-keyring, pas ici

[universes.personal]
accent = "#a55cff"
[universes.work]
accent = "#45a5ff"
[universes.gaming]
accent = "#ff4da6"
```

**DoD.** Settings panel s'ouvre via gear icon, affiche la matrice, toggle persiste après redémarrage du shell.

---

### Phase 10 — gnome-keyring (libsecret) (≈ 2 h)

**Objectif.** Stocker et lire le token HA dans le keyring via `secret-tool` CLI.

**Tâches.**
1. `src/services/Secrets.qml` :
   - `storeHaToken(token)` → `Process` `secret-tool store --label="Kama-Shell HA" service kama-shell token ha` avec `token` en stdin
   - `fetchHaToken()` → `Process` `secret-tool lookup service kama-shell token ha`, retourne une Promise
2. Logs minimaux si `secret-tool` absent ou keyring verrouillé ; exposer `available: bool`.

**DoD.** `Secrets.fetchHaToken()` retourne le token stocké. Pas de token en clair dans le TOML.

---

### Phase 11 — Home Assistant widget (≈ 10 h)

**Objectif.** Widget Home right-edge : WebSocket HA, état des entités configurées, commandes basiques.

**Tâches.**
1. `src/services/HomeAssistant.qml` :
   - `WebSocket { url: Config.ha.baseUrl.replace(/^http/, "ws") + "/api/websocket" }`
   - Flow d'auth : `auth_required` → `{type: "auth", access_token: …}` → reconnexion exponentielle sur `close`
   - Subscribe `state_changed`, maintenir `entityStates: { [entity_id]: {state, attributes} }`
   - `callService(domain, service, data)` pour les commandes
   - Indicateur `connection: "connecting" | "online" | "offline"`
2. `src/widgets/HomeWidget.qml` : prend la liste d'entités de `Config.widgets.home.entities`, affiche chacune avec état + toggle/slider selon `domain`.

**DoD.** Widget affiche l'état de `light.salon` (entité test), clic toggle la lumière, indicateur rouge si WS déconnecté.

---

### Phase 12 — Dynamic Island (≈ 12 h)

**Objectif.** Zone top-center qui morphe entre états : idle, MPRIS now-playing, download progress, recording indicator.

**Priorité d'affichage.** recording > download > mpris > idle.

**Tâches.**
1. `src/components/DynamicIsland.qml` : container avec `states` + `transitions`, `Behavior on width/height/radius { SpringAnimation }`.
2. Services sources :
   - `src/services/Mpris.qml` — DBus `org.mpris.MediaPlayer2`
   - `src/services/Downloads.qml` — mock initial (plus tard : portal ou Firefox/Chromium via DBus)
   - `src/services/Recording.qml` — `org.freedesktop.portal.ScreenCast` ; mock initial
3. Chaque état exporte son layout dans un `Component` chargé dynamiquement.
4. Priorité via `state: recording.active ? "rec" : download.active ? "dl" : mpris.playing ? "mpris" : "idle"`.

**DoD.** `playerctl play` fait apparaître la pill MPRIS avec morph fluide. Pause → retour idle.

---

### Phase 13 — Task dock hybride (≈ 16 h estimé, à confirmer)

**Objectif.** Pinned | separator | running-not-pinned.

**Stratégie toplevels.** Utiliser `Quickshell.Wayland.ToplevelManager`, qui expose les fenêtres via `zwlr-foreign-toplevel-management-v1`. Ne pas ajouter de fallback spécifique à un compositor.

**Tâches.**
1. Consommer `ToplevelManager.toplevels` depuis `DockState`.
2. Résoudre les métadonnées via `DesktopEntries`.
3. Garder `activate()` sur les toplevels comme action de focus.
4. Pinned list dans `Config.widgets.dock.pinned = ["firefox", "code", "foot"]`.
5. Intersection pinned + running → indicator point.

**DoD.** Dock affiche apps pinnées + apps ouvertes, clic focus la fenêtre, clic-droit menu contextuel.

---

### Phase 14+ — Post-MVP

- Focus Pod (Pomodoro) — bottom-left corner
- Agent tab (LLM query bar) — bottom-right corner
- Finance widget — stub en Phase 1, implémentation choix API (Nordigen / Plaid / manuel) à trancher plus tard
- Launcher `.desktop` parsing
- Gaming scanners : Steam, Lutris, Heroic, ProtonUp-Qt
- Dev scanners : `.git`, `package.json`, `Cargo.toml`, `pyproject.toml`, `docker-compose.yml` dans `~/Projects`, `~/Code`

Ces phases seront planifiées après le Jalon C.

---

## 5. Budget total

| Jalon | Phases | Heures cumulées |
|---|---|---|
| Jalon A — Shell de base | 0 → 7 | ≈ 54 h |
| Jalon B — Shell intégré | 8 → 11 | ≈ 80 h |
| Jalon C — Shell expressif | 12 → 13 | ≈ 108 h |

~1.5 semaine solo plein temps pour le Jalon A, ~3 semaines pour le Jalon C.

---

## 6. Structure de fichiers cible

```
glass-shell-qs/
├── PLAN.md
├── README.md
├── LESSONS.md
├── run.sh
├── shell.qml                      # entrypoint
├── showcase.qml                   # page de dev des primitives
├── qmldir                         # racine
├── docs/
│   └── integrations.md
├── images/
│   ├── maquette.png
│   └── wireframe.png
├── shaders/
│   └── pulse.frag
└── src/
    ├── Navigation.qml             # singleton état de nav
    ├── MonitorConfig.qml          # singleton géométrie par moniteur
    ├── PulseBus.qml               # singleton animation pulse
    ├── theme/
    │   ├── Tokens.qml
    │   ├── Spacing.qml
    │   ├── Motion.qml
    │   └── qmldir
    ├── primitives/
    │   ├── GlassSurface.qml
    │   ├── GlassCard.qml
    │   ├── GlassButton.qml
    │   ├── GlassSlider.qml
    │   ├── GlassToggle.qml
    │   ├── SectionTitle.qml
    │   ├── StatusChip.qml
    │   ├── MetricPill.qml
    │   └── qmldir
    ├── frame/
    │   ├── Frame.qml
    │   ├── FrameEdge.qml
    │   ├── PulseShader.qml
    │   ├── FrameGeometry.qml
    │   └── qmldir
    ├── components/
    │   ├── Sidebar.qml
    │   ├── UniverseSelector.qml
    │   ├── Header.qml
    │   ├── Dock.qml
    │   ├── DynamicIsland.qml
    │   └── qmldir
    ├── stage/
    │   └── Stage.qml
    ├── screens/
    │   ├── Dashboard.qml
    │   ├── Gaming.qml
    │   └── Dev.qml
    ├── services/
    │   ├── Cpu.qml
    │   ├── Ram.qml
    │   ├── Battery.qml
    │   ├── Network.qml
    │   ├── Wifi.qml
    │   ├── Bluetooth.qml
    │   ├── Focus.qml
    │   ├── Audio.qml
    │   ├── Brightness.qml
    │   ├── Clock.qml
    │   ├── Activities.qml
    │   ├── Mpris.qml
    │   ├── Downloads.qml
    │   ├── Recording.qml
    │   ├── Tasks.qml
    │   ├── Secrets.qml
    │   ├── HomeAssistant.qml
    │   └── qmldir
    ├── widgets/
    │   ├── HomeWidget.qml
    │   ├── FinanceWidget.qml
    │   ├── FocusPod.qml
    │   └── qmldir
    ├── settings/
    │   ├── SettingsPanel.qml
    │   ├── SettingsState.qml
    │   └── qmldir
    └── config/
        ├── Config.qml
        ├── tomlParser.js
        └── qmldir
```

---

## 7. Risques et mitigations

| Risque | Impact | Mitigation |
|---|---|---|
| Pulse cross-monitor non synchrone (frame callbacks Wayland par surface) | Tearing visuel du glow entre écrans | Fallback : glow isolé par moniteur, pas d'effet bord-à-bord. À évaluer en Phase 3 avant Phase 7 |
| `wlr-foreign-toplevel` absent côté compositor | Task dock limité aux apps pinned | Garder le dock utilisable sans running state; choisir Niri/labwc comme compositors cibles car ils exposent les protocoles wlroots attendus |
| Parser TOML JS introuvable | Config delay | Fallback JSON, non bloquant |
| NVIDIA + Qt Wayland hiccups (tearing, VRR) | Glitches visuels | `QT_QPA_PLATFORM=wayland`, `QT_WAYLAND_DISABLE_WINDOWDECORATION=1` ; surveiller les logs |
| Quickshell breaking changes (projet en beta) | Régression sur un upgrade | Pinner la version via commit précis si stabilité nécessaire |
| `secret-tool` absent sur machine fraîche | HA token illisible | Installer `libsecret` en prérequis, exposer `Secrets.available: bool` avec fallback explicite |

---

## 8. Protocole de commit

- Un commit par phase terminée, titre : `Phase N — <titre>` (copié de ce fichier).
- Push après Phase 0 (bootstrap fonctionnel), puis par groupes cohérents.
- Maintenir `PLAN.md` à jour : cocher les DoD au fur et à mesure, documenter les écarts dans une section "Changelog" ajoutée quand elle devient nécessaire.

---

## 9. Prochaine action concrète

**Lancer la Phase 0.** Installer `quickshell-git` et `niri`, écrire le `shell.qml` de ~15 lignes, vérifier que ça tourne sur la session Kama Shell.
