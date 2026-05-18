# AGENTS.md

Ce dépôt contient une configuration Quickshell minimale, actuellement centrée sur [`src/shell.qml`](src/shell.qml). Kama Shell est un shell Quickshell autonome lancé dans une session [niri](https://niri-wm.github.io/niri/). niri est la seule cible de session supportée; les intégrations KWin/KRunner ont été retirées (voir [`docs/TO_NIRI.md`](docs/TO_NIRI.md)). Les changements doivent rester compatibles avec Quickshell et avec un usage Wayland via `PanelWindow` + `WlrLayershell`.

## Objectif

- Garder une configuration Quickshell simple, lisible et facilement rechargeable.
- Éviter les patterns QML qui cassent le hot reload, le LSP, ou la réutilisabilité.
- Préparer le dépôt à évoluer vers plusieurs composants sans recréer inutilement logique et processus par fenêtre.

## Règles Quickshell

- Utiliser `PanelWindow` pour les barres, overlays et widgets attachés à un écran; réserver `FloatingWindow` aux fenêtres de bureau classiques.
- Ne pas utiliser d'imports `root:/...`; la documentation Quickshell indique que cela casse le LSP et les singletons.
- Si la config doit apparaître sur plusieurs écrans, préférer `Variants { model: Quickshell.screens }` au lieu de sélectionner un écran unique manuellement.
- Quand plusieurs fenêtres partagent le même état ou la même logique, sortir cet état dans un `Singleton` ou un `Scope` au lieu de dupliquer `Process`, `Timer` ou services dans chaque `PanelWindow`.
- Si un état global doit être accessible partout, préférer `pragma Singleton` + `Singleton { ... }`.
- Pour l'heure, les dates, ou d'autres sources système déjà exposées par Quickshell, préférer les services natifs comme `SystemClock` plutôt que lancer des commandes externes.
- Laisser `Quickshell.watchFiles` à son comportement par défaut sauf besoin explicite; le rechargement automatique fait partie du workflow normal.

## Règles QML pour ce dépôt

- Favoriser des composants petits et nommés clairement si `shell.qml` grossit.
- Si la configuration dépasse une seule fenêtre, extraire en priorité:
  - les composants visuels dans des fichiers dédiés `*.qml`
  - l'état partagé dans des singletons
  - les constantes de layout dans des propriétés readonly clairement nommées
- Garder les bindings réactifs; éviter la logique impérative quand une propriété calculée suffit.
- Éviter de référencer depuis un objet partagé des `id` déclarés à l'intérieur d'un composant `Variants` ou d'une fenêtre répliquée; la doc Quickshell montre que ce pattern casse dès qu'on sort la logique hors du composant local.
- Préférer `required property` pour les données injectées par `Variants`.

## Fenêtres et Wayland

- `anchors` de `PanelWindow` doivent être définis explicitement; sans ancrage, une mauvaise configuration peut bloquer l'écran ou produire un placement ambigu.
- Si deux côtés opposés sont ancrés, Quickshell force la dimension correspondante à la taille de l'écran. Utiliser `margins` pour créer un retrait visuel sans perdre l'ancrage.
- `exclusiveZone` ne fonctionne que si 1 ou 3 ancres sont actives. Ne pas l'ajouter sans vérifier cette contrainte.
- Laisser `focusable: false` sauf besoin clavier explicite; c'est la valeur par défaut et le comportement attendu pour une barre ou un overlay passif.
- Toute personnalisation directe de `WlrLayershell.layer` ou `WlrLayershell.namespace` doit être motivée par le comportement Wayland recherché.

## Structure recommandée

Si le projet évolue, viser cette organisation:

- `shell.qml`: point d'entrée, composition haut niveau, écrans, fenêtre(s)
- `components/`: primitives visuelles réutilisables
- `modules/` ou `widgets/`: blocs fonctionnels
- `state/`: singletons Quickshell (`pragma Singleton`)

Ne faire cette extraction que lorsque cela réduit réellement la duplication.

## Structure actuelle

- `src/shell.qml`: point d'entrée Quickshell
- `src/components/Ring.qml`: `PanelWindow` multi-écran et composition haut niveau du ring; délègue les métriques/contenus à `RingPanels`, le mask à `RingRegions`, et le dessin à `RingSurfaceRenderer`
- `src/components/RingPanels.qml`: composition des slots internes fixes du ring (`DateTimeNotch`, `StatusNotch`, `HomePanel`, handle maison, `ExpandableEdgeWidget` + `AppDock`) et exposition des items interactifs au mask
- `src/components/RingSlotModel.qml`: modèle géométrique interne des slots du ring; consomme les dimensions de fenêtre et états de reveal des panels pour produire les métriques utilisées par le rendu, le mask et le blur
- `src/components/RingRegions.qml`: `mask: Region` du ring, construit depuis `RingSlotModel`/`RingPanels`; soustrait la silhouette intérieure et ajoute les zones interactives du dock et du panel maison
- `src/components/RingSurfaceRenderer.qml`, `RingSdfSurface.qml`, `RingShapeSurface.qml`: rendu du ring depuis les métriques des slots; `RingSdfSurface` utilise `src/shaders/ring_sdf.frag.qsb`, `RingShapeSurface` conserve le fallback `ShapePath`
- `src/shaders/ring_sdf.frag`, `src/shaders/ring_sdf.frag.qsb`: shader SDF du ring et version Qt Shader Baker précompilée; régénérer avec `/usr/lib/qt6/bin/qsb --qt6 -o src/shaders/ring_sdf.frag.qsb src/shaders/ring_sdf.frag` après modification du `.frag`
- `src/components/RingSilhouettePath.qml`: `ShapePath` réutilisable qui dessine la silhouette intérieure complète du ring (top edge, clock notch, upper-right arc, right edge, home panel évidement, lower-right arc, dock bump, lower-left arc, left edge, upper-left arc). Mode `withOuterRectangle` pour le fill OddEvenFill; propriété `inset` pour les variantes outline. Fallback de rendu et source utilisée par `RingRegions`
- `src/state/RingPath.qml` (singleton): producteur JS des segments de la silhouette intérieure. Helpers `line/cubic/arc` + `buildInnerSegments(g)` qui retourne le tableau ordonné. **Source de vérité côté CPU**, consommée par `RingBlurRegion`
- `src/components/RingBlurRegion.qml`: génération exacte du `BackgroundEffect.blurRegion` du ring via `RingPath.buildInnerSegments(g)` et un scan-line pixel-spans CPU; ne pas remplacer par des rectangles approximatifs
- `src/components/DateTimeNotch.qml`: encoche haute centrale affichant la date et l'heure
- `src/components/StatusNotch.qml`, `StatusTrayIcon.qml`: encoche haute droite fixe affichant les items `SystemTray` déclarés par les apps et les indicateurs système volume/réseau/batterie
- `src/state/TrayMenuState.qml`, `src/components/TrayMenuOverlay.qml`, `TrayMenuPanel.qml`: état et rendu QML du menu contextuel `SystemTray`; évite les menus natifs Qt (`QMenu`) qui deviennent des `xdg-toplevel` problématiques sous niri/layer-shell
- `src/components/HomePanel.qml`: contenu visuel du panel maison, intégré dans le `PanelWindow` du ring
- `src/components/HomeRoomRow.qml`, `HomeDeviceControl.qml`, `HouseIcon.qml`: primitives visuelles du panel maison
- `src/components/AppDock.qml`: layout visuel du dock
- `src/components/ThemedPanelSurface.qml`, `LiquidGlassSurface.qml`: surfaces de panel thémables, avec rendu Liquid Glass; les surfaces simples peuvent utiliser le blur compositeur via `BackgroundEffect.blurRegion` quand leur région est exacte, avec fallback wallpaper local sinon
- `src/components/AppLauncherOverlay.qml`, `AppLauncher.qml`, `AppLauncherItem.qml`: overlay launcher multi-écran, recherche et lignes de résultat
- `src/ipc/KamaShellIpc.qml`: cible IPC `kama-shell` pour ouvrir/fermer le launcher depuis un bind niri ou `qs ipc`
- `src/state/ShellConfig.qml`: configuration utilisateur lue depuis `~/.config/kama-shell/kama.conf`
- `scripts/update-kama-config.py`: écriture atomique des valeurs de config modifiées par l'interface
- `src/state/ShellTheme.qml`: thème visuel actif, actuellement `glassmorphism`, `ffxiv` et `liquid-glass`
- `src/state/ShellGeometry.qml`: constantes de forme partagées entre ring, dock et panel maison
- `src/state/CompositorState.qml`: détection du backend (`niri` / `generic-wlr` / `unknown`) et capacités (`hasNativeToplevels`, `hasNiriIpc`, `hasLayerRules`, `supportsBackgroundEffect`); priorité à `KAMA_COMPOSITOR` puis aux heuristiques d'environnement
- `src/state/NiriIpc.qml`: helper d'IPC vers niri qui wrappe `niri msg --json`, parse la sortie et ignore les champs inconnus
- `src/state/NiriWorkspaceState.qml`: état normalisé des outputs, workspaces et fenêtre focus exposé via `NiriIpc`; expose aussi des actions (`focusWorkspaceUp`, `toggleOverview`, etc.)
- `src/state/DockState.qml`: état global du dock, apps pinned + running via `DesktopEntries` et `ToplevelManager`
- `src/state/DockIconResolver.qml`: résolution et cache asynchrones des icônes du dock
- `src/state/LauncherState.qml`: état global du launcher, filtrage de `DesktopEntries.applications`, sélection et lancement
- `src/state/StatusNotchState.qml`: état global de l'encoche haut-droite; agrège `SystemTray.items`, `Pipewire.defaultAudioSink`, `Networking.devices` et `UPower.displayDevice`
- `sessions/kama-shell-niri-session`, `sessions/start-kama-shell-niri-session`, `sessions/kama-shell-niri.desktop`: session niri installable via Makefile/PKGBUILD; exporte `KAMA_COMPOSITOR=niri`, `XDG_CURRENT_DESKTOP=KamaShell:niri`
- `sessions/kama-shell-niri-debug-session`, `sessions/start-kama-shell-niri-debug-session`, `sessions/kama-shell-niri-debug.desktop`: session niri debug; lance `niri --config config/niri/config.kdl` depuis le tree source et expose `KAMA_DEV=1` + log dans `logs/kama-shell.log`. Installable via `make install-session-niri-debug` uniquement (jamais empaquetee)
- `config/niri/config.kdl.example`: exemple de configuration niri (lancement de Kama Shell installe, include optionnel de `niri-binds.kdl`, layer rules sur les namespaces `kama-shell-*`, services attendus)
- `config/niri/config.kdl`: variante dev consommee par la session debug, avec `spawn-at-startup "/usr/bin/quickshell" "-p" "src/shell.qml"` et include de `binds.dev.kdl` (chemins relatifs resolus contre `$APP_DIR/config/niri`)
- `config/niri/binds.kdl`, `config/niri/binds.dev.kdl`: binds niri separes de la config principale (`Mod+D`, screenshots, quit), version paquet et version source-tree
- `src/state/ClockState.qml`: état global de l'horloge basé sur `SystemClock`, sans processus externe
- `src/state/WallpaperState.qml`: source du wallpaper rendu par Kama Shell, lue depuis `appearance.wallpaper`
- `src/components/WallpaperWindow.qml`: `PanelWindow` multi-écran sur la couche `WlrLayer.Background` qui rend le wallpaper de référence et le fallback local des surfaces Liquid Glass

Pour le dock applicatif:

- garder la séparation nette entre état (`DockState`) et rendu (`AppDock`, `AppDockItem`)
- préférer `DesktopEntries` pour les métadonnées applicatives
- utiliser `ToplevelManager` comme source unique des fenêtres ouvertes; n'introduire un `NiriWindowBackend` basé sur `niri msg --json windows` que si `ToplevelManager` ne fournit pas un champ utile
- éviter d'introduire de nouveaux fallbacks spécifiques à une application si un fallback générique de résolution d'icônes suffit

Pour le launcher applicatif:

- garder la séparation nette entre état (`LauncherState`) et rendu (`AppLauncher`, `AppLauncherItem`)
- utiliser `DesktopEntries.applications` comme source native des applications affichées
- déclencher l'ouverture globale via `IpcHandler` cible `kama-shell`; le raccourci global est fourni par `config/niri/binds.kdl` ou par la config niri utilisateur — Kama Shell n'enregistre plus de raccourci global lui-même
- `launcher.shortcut` dans `~/.config/kama-shell/kama.conf` est purement documentaire: garder la clé en sync avec `config/niri/binds.kdl` ou le bind niri utilisateur si elle change, mettre à jour `config/kama.conf.example`

Pour l'intégration niri:

- consommer l'état compositeur via `CompositorState`; ne jamais lire `XDG_CURRENT_DESKTOP` ou `NIRI_SOCKET` ailleurs
- toute requête à `niri` doit passer par le singleton `NiriIpc` (`niri msg --json`), pas par un `Process` ad hoc
- déclarer les layer rules dans `~/.config/niri/config.kdl` (voir `config/niri/config.kdl.example`); les binds globaux vivent dans `config/niri/binds.kdl` et sont inclus via niri `include`; namespaces utilisés: `kama-shell-ring`, `kama-shell-launcher`, `kama-shell-wallpaper`, `kama-shell-tray-menu`
- ne jamais approximer le blur du `kama-shell-ring`: sa courbe visible est complexe; toute évolution géométrique (notch supplémentaire, panneau additionnel, changement de courbe) doit mettre à jour `src/components/RingSlotModel.qml`, le fallback `src/components/RingSilhouettePath.qml`, `src/state/RingPath.qml` (`buildInnerSegments`, consommé par `RingBlurRegion`) et le shader `src/shaders/ring_sdf.frag` puis régénérer son `.qsb`

## Documentation

- Maintenir la documentation au fil de l'eau dans le même changement que le code: structure actuelle, clés de configuration, exemples et comportements rechargeables doivent rester alignés.
- Quand une clé de `~/.config/kama-shell/kama.conf` est ajoutée, renommée, supprimée ou change de comportement, mettre à jour `config/kama.conf.example` dans le même patch.
- Quand un fichier QML, singleton, composant ou script devient un point d'extension durable, mettre à jour la section "Structure actuelle" sans attendre une passe de documentation séparée.
- Mettre à jour `PLAN.md` ou `LESSONS.md` uniquement si le changement invalide un plan, confirme une leçon durable, ou documente un écart important; éviter d'y recopier les détails déjà présents dans `AGENTS.md`.

## Vérification

- Après modification, relire `src/shell.qml` et vérifier que les imports Quickshell sont cohérents avec les types utilisés.
- En cas de refactor multi-écran, vérifier que chaque fenêtre reçoit bien son `screen` depuis `Quickshell.screens`.
- Si le dock change, vérifier le rendu initial des apps pinned et des apps running, y compris la résolution des icônes au premier chargement.
- Si une configuration utilisateur change, vérifier que l'exemple correspondant et le comportement de reload attendu sont documentés.
- Ne pas introduire de duplication de recommandations dans ce fichier; enrichir les sections existantes.

## Sources

- Skill `find-docs` via Context7: `/websites/quickshell_master`
- Guide d'introduction Quickshell: https://quickshell.org/docs/master/guide/introduction/
- Référence `Quickshell`: https://quickshell.org/docs/master/types/Quickshell/Quickshell/
- Référence `PanelWindow`: https://quickshell.org/docs/master/types/Quickshell/PanelWindow/

<!-- rtk-instructions v2 -->
# RTK (Rust Token Killer) - Token-Optimized Commands

## Golden Rule

**Always prefix commands with `rtk`**. If RTK has a dedicated filter, it uses it. If not, it passes through unchanged. This means RTK is always safe to use.

**Important**: Even in command chains with `&&`, use `rtk`:
```bash
# ❌ Wrong
git add . && git commit -m "msg" && git push

# ✅ Correct
rtk git add . && rtk git commit -m "msg" && rtk git push
```

## RTK Commands by Workflow

### Build & Compile (80-90% savings)
```bash
rtk cargo build         # Cargo build output
rtk cargo check         # Cargo check output
rtk cargo clippy        # Clippy warnings grouped by file (80%)
rtk tsc                 # TypeScript errors grouped by file/code (83%)
rtk lint                # ESLint/Biome violations grouped (84%)
rtk prettier --check    # Files needing format only (70%)
rtk next build          # Next.js build with route metrics (87%)
```

### Test (60-99% savings)
```bash
rtk cargo test          # Cargo test failures only (90%)
rtk go test             # Go test failures only (90%)
rtk jest                # Jest failures only (99.5%)
rtk vitest              # Vitest failures only (99.5%)
rtk playwright test     # Playwright failures only (94%)
rtk pytest              # Python test failures only (90%)
rtk rake test           # Ruby test failures only (90%)
rtk rspec               # RSpec test failures only (60%)
rtk test <cmd>          # Generic test wrapper - failures only
```

### Git (59-80% savings)
```bash
rtk git status          # Compact status
rtk git log             # Compact log (works with all git flags)
rtk git diff            # Compact diff (80%)
rtk git show            # Compact show (80%)
rtk git add             # Ultra-compact confirmations (59%)
rtk git commit          # Ultra-compact confirmations (59%)
rtk git push            # Ultra-compact confirmations
rtk git pull            # Ultra-compact confirmations
rtk git branch          # Compact branch list
rtk git fetch           # Compact fetch
rtk git stash           # Compact stash
rtk git worktree        # Compact worktree
```

Note: Git passthrough works for ALL subcommands, even those not explicitly listed.

### GitHub (26-87% savings)
```bash
rtk gh pr view <num>    # Compact PR view (87%)
rtk gh pr checks        # Compact PR checks (79%)
rtk gh run list         # Compact workflow runs (82%)
rtk gh issue list       # Compact issue list (80%)
rtk gh api              # Compact API responses (26%)
```

### JavaScript/TypeScript Tooling (70-90% savings)
```bash
rtk pnpm list           # Compact dependency tree (70%)
rtk pnpm outdated       # Compact outdated packages (80%)
rtk pnpm install        # Compact install output (90%)
rtk npm run <script>    # Compact npm script output
rtk npx <cmd>           # Compact npx command output
rtk prisma              # Prisma without ASCII art (88%)
```

### Files & Search (60-75% savings)
```bash
rtk ls <path>           # Tree format, compact (65%)
rtk read <file>         # Code reading with filtering (60%)
rtk grep <pattern>      # Search grouped by file (75%)
rtk find <pattern>      # Find grouped by directory (70%)
```

### Analysis & Debug (70-90% savings)
```bash
rtk err <cmd>           # Filter errors only from any command
rtk log <file>          # Deduplicated logs with counts
rtk json <file>         # JSON structure without values
rtk deps                # Dependency overview
rtk env                 # Environment variables compact
rtk summary <cmd>       # Smart summary of command output
rtk diff                # Ultra-compact diffs
```

### Infrastructure (85% savings)
```bash
rtk docker ps           # Compact container list
rtk docker images       # Compact image list
rtk docker logs <c>     # Deduplicated logs
rtk kubectl get         # Compact resource list
rtk kubectl logs        # Deduplicated pod logs
```

### Network (65-70% savings)
```bash
rtk curl <url>          # Compact HTTP responses (70%)
rtk wget <url>          # Compact download output (65%)
```

### Meta Commands
```bash
rtk gain                # View token savings statistics
rtk gain --history      # View command history with savings
rtk discover            # Analyze Claude Code sessions for missed RTK usage
rtk proxy <cmd>         # Run command without filtering (for debugging)
rtk init                # Add RTK instructions to CLAUDE.md
rtk init --global       # Add RTK to ~/.claude/CLAUDE.md
```

## Token Savings Overview

| Category | Commands | Typical Savings |
|----------|----------|-----------------|
| Tests | vitest, playwright, cargo test | 90-99% |
| Build | next, tsc, lint, prettier | 70-87% |
| Git | status, log, diff, add, commit | 59-80% |
| GitHub | gh pr, gh run, gh issue | 26-87% |
| Package Managers | pnpm, npm, npx | 70-90% |
| Files | ls, read, grep, find | 60-75% |
| Infrastructure | docker, kubectl | 85% |
| Network | curl, wget | 65-70% |

Overall average: **60-90% token reduction** on common development operations.
<!-- /rtk-instructions -->
