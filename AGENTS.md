# AGENTS.md

Ce dépôt contient Kama Shell, un shell Quickshell autonome lancé dans une session [niri](https://niri-wm.github.io/niri/). niri est la seule cible de session supportée; les intégrations KWin/KRunner ont été retirées. Les changements doivent rester compatibles avec Quickshell, Wayland, `PanelWindow` et `WlrLayershell`.

## Lecture initiale obligatoire

Avant toute tâche de développement, lire dans cet ordre, sans rescanner tout le projet:

1. `docs/TECH.md` — architecture technique, carte du code, pipeline du ring, singletons, namespaces layer-shell, IPC, conventions. Sert de source de vérité pour la structure. Doit être mis à jour dans la même PR que tout changement qui le contredit (liste des cas dans `docs/TECH.md` §13).
2. `docs/LESSONS.md` — pièges déjà confirmés en session réelle. Ne pas réintroduire un pattern explicitement documenté comme problématique.
3. Ce fichier (`AGENTS.md`) — règles non négociables; prévaut sur `TECH.md` en cas de désaccord.
4. `docs/DEBT.md` et `docs/PERFORMANCE.md` quand le changement touche les zones concernées (ring, blur, animations).

Ne lire le code en exploration qu'après ces fichiers. Si une information manque dans `docs/TECH.md`, l'y ajouter en même temps que le changement.

## Objectif

- Garder une configuration Quickshell simple, lisible et facilement rechargeable.
- Éviter les patterns QML qui cassent le hot reload, le LSP ou la réutilisabilité.
- Préparer le dépôt à évoluer vers plusieurs composants sans recréer inutilement logique et processus par fenêtre.

## Règles Quickshell et QML

- Utiliser `PanelWindow` pour les barres, overlays et widgets attachés à un écran; réserver `FloatingWindow` aux fenêtres de bureau classiques.
- Ne pas utiliser d'imports `root:/...`; la documentation Quickshell indique que cela casse le LSP et les singletons.
- Si la config doit apparaître sur plusieurs écrans, préférer `Variants { model: Quickshell.screens }` au lieu de sélectionner un écran unique manuellement.
- Préférer `required property` pour les données injectées par `Variants`.
- Quand plusieurs fenêtres partagent le même état ou la même logique, sortir cet état dans un `Singleton` ou un `Scope` au lieu de dupliquer `Process`, `Timer` ou services.
- Si un état global doit être accessible partout, préférer `pragma Singleton` + `Singleton { ... }`.
- Pour l'heure, les dates ou d'autres sources système déjà exposées par Quickshell, préférer les services natifs comme `SystemClock` plutôt que lancer des commandes externes.
- Laisser `Quickshell.watchFiles` à son comportement par défaut sauf besoin explicite; le rechargement automatique fait partie du workflow normal.
- Favoriser des composants petits et nommés clairement si `shell.qml` grossit.
- Si la configuration dépasse une seule fenêtre, extraire en priorité:
  - les composants visuels dans des fichiers dédiés `*.qml`
  - l'état partagé dans des singletons
  - les constantes de layout dans des propriétés readonly clairement nommées
- Garder les bindings réactifs; éviter la logique impérative quand une propriété calculée suffit.
- Éviter de référencer depuis un objet partagé des `id` déclarés à l'intérieur d'un composant `Variants` ou d'une fenêtre répliquée; la doc Quickshell montre que ce pattern casse dès qu'on sort la logique hors du composant local.

## Wayland, niri et fenêtres

- `anchors` de `PanelWindow` doivent être définis explicitement; sans ancrage, une mauvaise configuration peut bloquer l'écran ou produire un placement ambigu.
- Si deux côtés opposés sont ancrés, Quickshell force la dimension correspondante à la taille de l'écran. Utiliser `margins` pour créer un retrait visuel sans perdre l'ancrage.
- `exclusiveZone` ne fonctionne que si 1 ou 3 ancres sont actives. Ne pas l'ajouter sans vérifier cette contrainte.
- Laisser `focusable: false` sauf besoin clavier explicite; c'est la valeur par défaut et le comportement attendu pour une barre ou un overlay passif.
- Toute personnalisation directe de `WlrLayershell.layer` ou `WlrLayershell.namespace` doit être motivée par le comportement Wayland recherché.
- Consommer l'état compositeur via `CompositorState`; ne jamais lire `XDG_CURRENT_DESKTOP` ou `NIRI_SOCKET` ailleurs.
- Toute requête à `niri` doit passer par le singleton `NiriIpc` (`niri msg --json`), pas par un `Process` ad hoc.
- Les binds globaux vivent dans `config/niri/binds.kdl` et sont inclus via niri `include`; Kama Shell n'enregistre plus de raccourci global lui-même.
- Tout nouveau `PanelWindow` qui utilise `BackgroundEffect.blurRegion` doit avoir une `layer-rule` avec `background-effect { xray false }` dans `config/niri/config.kdl` et `config/niri/config.kdl.example`, dans le même patch que le composant.

## Structure recommandée

Si le projet évolue, viser cette organisation:

- `shell.qml`: point d'entrée, composition haut niveau, écrans, fenêtre(s)
- `components/`: primitives visuelles réutilisables
- `modules/` ou `widgets/`: blocs fonctionnels
- `state/`: singletons Quickshell (`pragma Singleton`)

Ne faire cette extraction que lorsque cela réduit réellement la duplication.

## Structure actuelle

### Entrée et fenêtres principales

- `src/shell.qml`: point d'entrée Quickshell
- `src/components/WallpaperWindow.qml`: `PanelWindow` multi-écran sur la couche `WlrLayer.Background`; rend le wallpaper de référence et le fallback local des surfaces Liquid Glass
- `src/components/Ring.qml`: `PanelWindow` multi-écran et composition haut niveau du ring; délègue les métriques/contenus à `RingPanels`, le mask à `RingRegions` et le dessin à `RingSurfaceRenderer`
- `src/components/TrayMenuOverlay.qml`, `TrayMenuPanel.qml`, `src/state/TrayMenuState.qml`: état et rendu QML du menu contextuel `SystemTray`
- `src/components/SessionActionsOverlay.qml`, `SessionActionsPanel.qml`, `src/state/SessionActionsState.qml`: popup d'actions session ouvert depuis le bouton du dock; propose `Déconnexion`, `Redémarrer`, `Éteindre`
- `src/components/AppLauncherOverlay.qml`, `AppLauncher.qml`, `AppLauncherItem.qml`: overlay launcher multi-écran, recherche et lignes de résultat
- `src/components/SettingsOverlay.qml`, `SettingsPanel.qml`, `SettingsMenu.qml`, `SettingsContent.qml`: overlay panel paramètres plein écran, multi-écran, focus clavier exclusif (`kama-shell-settings`), scrim + blur; menu sidebar gauche (240 px) + zone contenu droite chargée par `Loader` selon `SettingsState.selectedSection`
- `src/components/settings/AppearanceSection.qml`, `settings/ThemePreviewCard.qml`: section Apparence du panel paramètres; cartes d'aperçu de thème (image statique 280×180 depuis `src/assets/previews/theme-<id>.png`) qui appellent `ShellConfig.saveTheme()` au clic; les PNG sont des placeholders à remplacer par de vrais screenshots (format cible: 560×360)
- `src/components/settings/HomeSection.qml`: section Maison du panel paramètres; édite `homeAssistant.url` et `homeAssistant.token` via `ShellConfig.saveHomeAssistantConfig()` pour préparer l'accès à une API Home Assistant
- `src/ipc/KamaShellIpc.qml`: cible IPC `kama-shell` pour ouvrir/fermer le launcher, déclencher les commandes de luminosité et ouvrir/fermer le panel paramètres (`toggleSettings`, `showSettings`, `hideSettings`) depuis un bind niri ou `qs ipc`
- `src/components/OsdOverlay.qml`: `PanelWindow` multi-écran (`Variants { model: Quickshell.screens }`) plein-écran transparent, namespace `kama-shell-osd`, `WlrLayer.Overlay`, passe-clic (`mask: Region {}`); contient `OsdPanel` centré en bas à 56 px du bas avec fade + slide animés; `BackgroundEffect.blurRegion` activé sous thème `liquid-glass` + compositeur compatible
- `src/components/OsdPanel.qml`: pill `LiquidGlassSurface` (320×56, `radius: height/2`) affichant une icône Fluent UI (volume ou luminosité) et une barre de progression `SmoothedAnimation`

### Ring et géométrie

- `src/components/RingPanels.qml`: composition des slots internes fixes du ring (`DateTimeNotch`, `StatusNotch`, `HomePanel`, handle maison, `ExpandableEdgeWidget` + `AppDock`) et exposition des items interactifs au mask
- `src/components/RingSlotModel.qml`: modèle géométrique interne des slots du ring; consomme les dimensions de fenêtre et états de reveal des panels pour produire les métriques utilisées par le rendu, le mask et le blur
- `src/components/RingRegions.qml`: `mask: Region` du ring, construit depuis `RingSlotModel`/`RingPanels`; soustrait la silhouette intérieure et ajoute les zones interactives du dock et du panel maison
- `src/components/RingSurfaceRenderer.qml`, `RingShapeSurface.qml`: rendu Shape du ring depuis le modèle géométrique des slots; `RingShapeSurface` utilise `Shape.CurveRenderer` et reste la référence visuelle
- `src/components/RingSilhouettePath.qml`: `ShapePath` réutilisable généré via `PathSvg` depuis `RingPath.buildSvgPath`; dessine la silhouette intérieure complète du ring, avec mode `withOuterRectangle` pour le fill OddEvenFill et propriété `inset` pour les variantes outline. Source utilisée par `RingShapeSurface` et `RingRegions`
- `src/state/RingPath.qml` (singleton): producteur JS de la silhouette intérieure. Normalise le modèle géométrique, génère les segments CPU (`buildInnerSegments`) et le chemin SVG (`buildSvgPath`). **Source de vérité des contours**, consommée par `RingSilhouettePath` et `RingBlurRegion`
- `src/components/RingBlurRegion.qml`: génération exacte du `BackgroundEffect.blurRegion` du ring via `RingPath.buildInnerSegments(g)`; ne pas remplacer par des rectangles approximatifs
- `src/state/ShellGeometry.qml`: constantes de forme partagées entre ring, dock et panel maison

Ne jamais approximer le blur du `kama-shell-ring`: toute évolution géométrique visible (notch supplémentaire, panneau additionnel, changement de courbe) doit garder alignés `RingSlotModel`, `RingSilhouettePath`, `RingPath` et `RingBlurRegion`.

### Widgets et surfaces

- `src/components/DateTimeNotch.qml`: encoche haute centrale affichant la date et l'heure
- `src/components/StatusNotch.qml`, `StatusTrayIcon.qml`: encoche haute droite fixe affichant les items `SystemTray` déclarés par les apps et les indicateurs système volume/réseau/CPU/GPU/batterie
- `src/assets/icons/status/`: icônes Fluent UI System embarquées pour les indicateurs système internes du `StatusNotch`; les icônes tray applicatives restent fournies par `SystemTray`. Toute nouvelle icône système interne doit être récupérée de la même façon (SVG Fluent UI System via Iconify/API ou source upstream, licence MIT documentée dans le README local) puis embarquée ici avec un fill blanc explicite.
- `src/assets/icons/fluent/`: icônes SVG Fluent UI System embarquées pour les actions du dock (`fluent-apps-24-regular.svg` pour le launcher, `fluent-settings-24-regular.svg` pour le bouton paramètres, `fluent-sign-out-24-regular.svg` pour le bouton session) et le menu paramètres (`fluent-color-24-regular.svg`, `fluent-home-24-regular.svg`); le popup session ajoute `fluent-arrow-clockwise-24-regular.svg` et `fluent-power-24-regular.svg`. Fill blanc explicite, taille 24 px, même convention que les icônes status.
- `src/assets/previews/`: images PNG (560×360) utilisées comme aperçus de thème dans le panel paramètres (`theme-liquid-glass.png`, `theme-ffxiv.png`). Ces fichiers sont des placeholders à remplacer par de vrais screenshots; le composant `ThemePreviewCard` gère un fallback visuel si l'image est manquante.
- `src/components/HomePanel.qml`: contenu visuel du panel maison, intégré dans le `PanelWindow` du ring; consomme `HomeAssistantState`; gère les états loading/error/non-configuré
- `src/components/HomeRoomRow.qml`, `HomeDeviceControl.qml`, `HouseIcon.qml`: primitives visuelles du panel maison; `HomeRoomRow` lit `modelData` issu de `HomeAssistantState.rooms` et déclenche les actions sur le singleton; `HomeDeviceControl` supporte le mode `adjustable` (boutons +/−) pour le thermostat
- `src/components/AppDock.qml`, `AppDockItem.qml`, `DockSeparator.qml`: layout visuel du dock
- `src/components/ExpandableEdgeWidget.qml`: primitive de widget rétractable intégrée au ring
- `src/components/ThemedPanelSurface.qml`, `LiquidGlassSurface.qml`: surfaces de panel thémables, avec rendu Liquid Glass; les surfaces simples peuvent utiliser le blur compositeur via `BackgroundEffect.blurRegion` quand leur région est exacte

### État global

- `src/state/OsdState.qml` (singleton): état de l'OSD volume/luminosité; observe `StatusNotchState.audioVolume/audioMuted` pour le volume (déclenché automatiquement quand `wpctl` modifie le sink Pipewire) et expose `brightnessUp()`/`brightnessDown()` (appelés via IPC, exécutent `brightnessctl -m set 5%±` et parsent le CSV de sortie); auto-masquage après 2.5 s via `Timer`; propriétés `kind` (0=none, 1=volume, 2=brightness), `level` (0–1), `muted`, `visible`
- `src/state/ShellConfig.qml`: configuration utilisateur lue depuis `~/.config/kama-shell/kama.conf`
- `src/state/ShellTheme.qml`: thème visuel actif, actuellement `ffxiv` et `liquid-glass`
- `src/state/CompositorState.qml`: détection du backend (`niri` / `generic-wlr` / `unknown`) et capacités (`hasNativeToplevels`, `hasNiriIpc`, `hasLayerRules`, `supportsBackgroundEffect`); priorité à `KAMA_COMPOSITOR` puis aux heuristiques d'environnement
- `src/state/NiriIpc.qml`: helper d'IPC vers niri qui wrappe `niri msg --json`, parse la sortie et ignore les champs inconnus
- `src/state/NiriWindowBackend.qml`: source normalisée des fenêtres sous niri (`niri msg --json windows` + event stream); expose `workspaceId`, `isFloating`, `isFullscreen` et `layout` pour le dock et la détection fullscreen par output
- `src/state/NiriWorkspaceState.qml`: état normalisé des outputs, workspaces et fenêtre focus exposé via `NiriIpc`; expose aussi la détection fullscreen par écran (`hasFullscreenOnScreen`, `fullscreenOutputNames`) et des actions (`focusWorkspaceUp`, `toggleOverview`, etc.)
- `src/state/DockState.qml`: état global du dock, apps pinned + running via `DesktopEntries` et `ToplevelManager`
- `src/state/DockIconResolver.qml`: résolution et cache asynchrones des icônes du dock
- `src/state/LauncherState.qml`: état global du launcher, filtrage de `DesktopEntries.applications`, sélection et lancement
- `src/state/SettingsState.qml`: état du panel paramètres (`visible`, `selectedSection`, `targetScreenName`); méthodes `show/hide/toggle`; helpers multi-écran identiques à `LauncherState`
- `src/state/StatusNotchState.qml`: état global de l'encoche haut-droite; agrège `SystemTray.items`, `Pipewire.defaultAudioSink`, `Networking.devices`, `/proc/stat`, la charge GPU via provider disponible et `UPower.displayDevice`
- `src/state/ClockState.qml`: état global de l'horloge basé sur `SystemClock`, sans processus externe
- `src/state/WallpaperState.qml`: source du wallpaper rendu par Kama Shell, lue depuis `appearance.wallpaper`
- `src/state/HomeAssistantState.qml`: état domotique Home Assistant; requêtes `XMLHttpRequest` vers `POST /api/template` (Jinja2 room data) et `POST /api/services/{domain}/{service}` (actions); auto-refresh 30 s; mise à jour optimiste + refresh différé 1.5 s après action; expose `rooms[]`, `loading`, `error`, `connected`, `isConfigured`

### Configuration, scripts et sessions

- `scripts/update-kama-config.py`: écriture atomique des valeurs de config modifiées par l'interface; sous-commandes `pinned-apps CONFIG_PATH VALUE` (apps épinglées du dock), `set-key CONFIG_PATH SECTION.KEY VALUE` (écriture générique d'une clé INI, ex. `appearance.theme`) et `set-keys CONFIG_PATH SECTION.KEY VALUE [...]` (écriture atomique de plusieurs clés, ex. Home Assistant)
- `sessions/kama-shell-niri-session`, `sessions/start-kama-shell-niri-session`, `sessions/kama-shell-niri.desktop`: session niri installable via Makefile/PKGBUILD; exporte `KAMA_COMPOSITOR=niri`, `XDG_CURRENT_DESKTOP=KamaShell:niri`
- `sessions/kama-shell-niri-debug-session`, `sessions/start-kama-shell-niri-debug-session`, `sessions/kama-shell-niri-debug.desktop`: session niri debug; lance `niri --config config/niri/config.kdl` depuis le tree source et expose `KAMA_DEV=1` + log dans `logs/kama-shell.log`. Installable via `make install-session-niri-debug` uniquement (jamais empaquetée)
- `config/niri/config.kdl.example`: exemple de configuration niri (lancement de Kama Shell installé, include optionnel de `niri-binds.kdl`, layer rules sur les namespaces `kama-shell-*`, services attendus)
- `config/niri/config.kdl`: variante dev consommée par la session debug, avec `spawn-at-startup "/usr/bin/quickshell" "-p" "src/shell.qml"` et include de `binds.dev.kdl` (chemins relatifs résolus contre `$APP_DIR/config/niri`)
- `config/niri/binds.kdl`, `config/niri/binds.dev.kdl`: binds niri séparés de la config principale (`Mod+D`, screenshots, quit, touches multimédias et luminosité); les touches `XF86MonBrightnessUp/Down` passent par IPC (`qs ipc call kama-shell brightnessUp/Down`) pour déclencher l'OSD; les touches volume appellent `wpctl` directement, l'OSD est déclenché en observant l'état Pipewire

## Dock et launcher

- Garder la séparation nette entre état (`DockState`, `LauncherState`) et rendu (`AppDock`, `AppDockItem`, `AppLauncher`, `AppLauncherItem`).
- Préférer `DesktopEntries` pour les métadonnées applicatives et `DesktopEntries.applications` pour le launcher.
- Sous niri, utiliser `NiriWindowBackend` comme source des fenêtres ouvertes; hors niri, conserver le fallback `ToplevelManager`. Ne pas ajouter un second backend fenêtre.
- Éviter d'introduire de nouveaux fallbacks spécifiques à une application si un fallback générique de résolution d'icônes suffit.
- Déclencher l'ouverture globale du launcher via `IpcHandler` cible `kama-shell`; le raccourci global est fourni par `config/niri/binds.kdl` ou par la config niri utilisateur.
- `launcher.shortcut` dans `~/.config/kama-shell/kama.conf` est purement documentaire: garder la clé en sync avec `config/niri/binds.kdl` ou le bind niri utilisateur si elle change, mettre à jour `config/kama.conf.example`

## Intégration niri

- Déclarer les layer rules dans `~/.config/niri/config.kdl` (voir `config/niri/config.kdl.example`).
- Namespaces utilisés: `kama-shell-ring`, `kama-shell-launcher`, `kama-shell-settings`, `kama-shell-wallpaper`, `kama-shell-tray-menu`, `kama-shell-session-actions`, `kama-shell-osd`.
- Ajouter `background-effect { xray false }` pour toute surface qui utilise `BackgroundEffect.blurRegion`.
- Ne pas ajouter `blur true` côté niri pour le ring: le ring fournit sa région exacte via `RingBlurRegion`.

## Documentation

- Maintenir la documentation au fil de l'eau dans le même changement que le code: structure actuelle, clés de configuration, exemples et comportements rechargeables doivent rester alignés.
- Lire `docs/LESSONS.md` avant de modifier du QML, du niri/layer-shell, du dock, du launcher, du ring, des icônes, des services Pipewire/UPower ou des processus; appliquer les leçons existantes avant d'ajouter du code.
- Mettre à jour `docs/TECH.md` dans la même PR pour tout ce qui touche: ajout/renommage/suppression d'un singleton ou d'une fenêtre, namespace layer-shell, layer-rule niri, méthode IPC `kama-shell`, clé `kama.conf`, pipeline géométrique du ring, ou source d'assets embarqués. Voir `docs/TECH.md` §13 pour la liste complète.
- Quand une clé de `~/.config/kama-shell/kama.conf` est ajoutée, renommée, supprimée ou change de comportement, mettre à jour `config/kama.conf.example` dans le même patch.
- Quand un fichier QML, singleton, composant ou script devient un point d'extension durable, mettre à jour la section "Structure actuelle" sans attendre une passe de documentation séparée.
- Quand une feature est validée (comportement confirmé en session réelle), enregistrer dans `docs/LESSONS.md` les leçons apprises pendant son développement: comportements surprenants d'API, contraintes non documentées, patterns qui ont fonctionné ou échoué, pièges à éviter. Ne pas y recopier ce qui est déjà dans `AGENTS.md`; se concentrer sur le "pourquoi ça a coincé" et "comment l'éviter la prochaine fois". Organiser par thème (ex. "Niri / Compositeur", "Processus / IO"), pas par feature.

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
