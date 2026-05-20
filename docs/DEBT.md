# Dette technique

Ce document centralise la dette technique identifiee dans Kama Shell. Il ne
remplace pas `docs/LESSONS.md`: `LESSONS.md` garde les pieges confirmes en
session reelle, tandis que ce fichier suit les zones a rembourser ou a
surveiller.

## Synthese

- La dette principale du ring a ete reduite: rendu, mask et blur consomment
  desormais le meme modele geometrique. Le risque restant est la validation
  visuelle et la couverture de tests autour de ce modele.
- La dette performance est liee au cout du ring anime, surtout
  `RingBlurRegion` et les `ShapePath` complexes pendant les ouvertures du dock
  et du panel maison.
- Le modele des fenetres niri est fragmente entre `NiriWindowBackend`,
  `NiriWorkspaceState`, `ToplevelManager` et `DockState`.
- La configuration utilisateur fonctionne, mais repose sur un parseur maison et
  une sauvegarde limitee aux apps epinglees du dock.
- Quelques dettes sont des bugs probables ou des incoherences courtes a corriger:
  chemins d'assets relatifs dans l'OSD, shortcut documentaire incoherent, logs
  tray trop verbeux et dependances runtime incompletes.

## P0 - Risques eleves

### Geometrie du ring unifiee, validation encore faible

Fichiers principaux:

- `src/components/Ring.qml`
- `src/components/RingPanels.qml`
- `src/components/RingSlotModel.qml`
- `src/components/RingRegions.qml`
- `src/components/RingSilhouettePath.qml`
- `src/components/RingBlurRegion.qml`
- `src/state/RingPath.qml`

Constat:

- `RingSlotModel` expose un modele `ringGeometry`.
- `RingPath` normalise ce modele et genere a la fois les segments CPU et le
  chemin SVG.
- `RingSilhouettePath`, `RingRegions` et `RingBlurRegion` consomment cette
  source commune.
- L'ancien prototype SDF a ete retire, car il ajoutait une cible approximative
  a synchroniser.

Risque:

- Toute evolution visible du ring peut encore diverger si elle contourne
  `ringGeometry` ou ajoute un consommateur qui ne passe pas par `RingPath`.
- Les regressions sont difficiles a detecter par `qmllint`; elles apparaissent
  surtout visuellement ou en session Wayland reelle.
- Ajouter une notch, un panel lateral ou une deformation impose encore de
  verifier les sorties SVG, CPU et mask ensemble.

Remboursement recommande:

- Etendre `tests/RingPathSelfTest.qml` avec plusieurs tailles et etats de
  reveal.
- Ajouter une validation visuelle manuelle documentee apres chaque changement
  de silhouette.
- Garder `RingShapeSurface` comme reference visuelle si un renderer alternatif
  est reintroduit.

### Cout CPU du blur et des animations du ring

Fichiers principaux:

- `src/components/RingBlurRegion.qml`
- `src/components/RingShapeSurface.qml`
- `src/components/RingRegions.qml`
- `src/components/ExpandableEdgeWidget.qml`
- `src/components/HomePanel.qml`
- `docs/PERFORMANCE.md`

Constat:

- `RingBlurRegion` reconstruit une region par scanline, compresse les spans et
  cree des `Region` dynamiques avec `Qt.createQmlObject`.
- Le pool de spans grandit a la demande mais ne retrecit pas.
- `docs/PERFORMANCE.md` documente deja un ralentissement des animations quand le
  CPU est charge.
- `Shape.CurveRenderer` et `asynchronous: true` sont appliques aux `Shape` du
  ring et du mask; leur gain reste a mesurer en session reelle.

Risque:

- Pics CPU pendant ouverture/fermeture du dock ou du panel maison.
- Rebuilds de blur trop frequents si les proprietes geometriques changent en
  cascade.
- Effet amplifie sur multi-ecran, car chaque `PanelWindow` replique le ring.

Remboursement recommande:

- Mesurer la passe v1 de `docs/PERFORMANCE.md`:
  `Shape.CurveRenderer`, `asynchronous: true`, animations courtes et trace
  `KAMA_TRACE_PERF`.
- Mesurer `RingBlurRegion` avec `KAMA_TRACE_PERF=1` avant/apres modification.
- Eviter tout retour a une region de blur approximative; la dette performance ne
  doit pas casser l'invariant geometrique.
- Si la v1 ne suffit pas, prioriser un renderer SDF exact base sur
  `ringGeometry` ou un item QSG dedie.

### Chemins d'assets embarques a surveiller

Fichier principal:

- `src/components/OsdPanel.qml`

Constat:

- L'OSD utilise maintenant `Qt.resolvedUrl(...)` pour les icones embarquees.
- `make test` lance `scripts/check-qml-asset-urls.py` pour bloquer les
  nouvelles concatenations relatives vers `../assets/`.
- `docs/LESSONS.md` documente que, sous le scheme `qs:@`, les chemins relatifs
  concatenees peuvent echouer silencieusement.

Risque:

- Le risque principal devient une regression future non couverte par le check
  statique si elle passe par une autre forme de chemin relatif.

Remboursement recommande:

- Garder la recherche de garde dans les reviews: toute URL source-tree QML doit
  passer par `Qt.resolvedUrl`.

## P1 - Architecture a stabiliser

### Modele de fenetres niri fragmente

Fichiers principaux:

- `src/state/DockState.qml`
- `src/state/NiriWindowBackend.qml`
- `src/state/NiriWorkspaceState.qml`
- `src/state/NiriIpc.qml`

Constat:

- `DockState.currentToplevels()` utilise `NiriWindowBackend.windows` sous niri,
  et `ToplevelManager` seulement hors niri.
- `NiriWorkspaceState` expose workspaces, outputs et focused window via d'autres
  requetes IPC.
- Les deux singletons normalisent des formes de fenetre differentes.
- La documentation recommande `ToplevelManager` comme source unique, sauf champ
  manquant.

Risque:

- Divergence entre fenetre active, dock, workspace focus et actions de focus.
- Ajout de features comme fullscreen retract ou workspace indicators plus couteux
  que necessaire.
- Evenements niri partiellement traites selon le singleton qui les recoit.

Remboursement recommande:

- Clarifier le contrat: soit `NiriWindowBackend` devient la source niri unique et
  documentee, soit on revient a `ToplevelManager` et on reserve l'IPC niri aux
  champs absents.
- Ajouter `isFullscreen`/`isFloating`/`workspaceId` si disponibles dans l'IPC niri
  et les exposer via un seul modele.
- Faire consommer ce modele par `DockState` et par tout futur comportement de
  retract fullscreen.

### Configuration utilisateur trop artisanale

Fichiers principaux:

- `src/state/ShellConfig.qml`
- `scripts/update-kama-config.py`
- `config/kama.conf.example`

Constat:

- Le parseur INI est implemente en QML: sections, commentaires, listes,
  scalaires, compat legacy.
- Le script de sauvegarde ne sait modifier que `dock.pinnedApps`.
- La cle `launcher.shortcut` est documentaire, mais son defaut interne
  `Meta` diverge des binds et de l'exemple `Mod+D`.
- Les themes ont une compat legacy (`visual.theme`) qui doit rester explicite
  tant que des configs utilisateur peuvent l'utiliser.

Risque:

- Incoherences entre config effective, exemple et binds niri.
- Extension de la config par copie de fonctions ad hoc.
- Erreurs de parsing silencieuses ou peu visibles pour l'utilisateur.

Remboursement recommande:

- Aligner `defaultLauncherShortcut` avec le bind documentaire actuel ou retirer
  l'exposition runtime si elle n'est jamais consommee.
- Encapsuler les cles supportees dans une petite table de schema: valeur par
  defaut, normaliseur, compat legacy, documentation.
- Etendre `update-kama-config.py` seulement avec des operations explicites, pas
  avec un editeur INI general improvise.
- Ajouter des tests Python/QML de parsing pour les cas: commentaires quotes,
  listes, `~/`, themes inconnus, `dock.pinned` legacy.

### DockState trop large

Fichiers principaux:

- `src/state/DockState.qml`
- `src/state/DockIconResolver.qml`
- `src/components/AppDock.qml`

Constat:

- `DockState.qml` orchestre pinned apps, running apps, matching desktop entries,
  lancement, pin/unpin, signatures et connexions a plusieurs sources.
- L'extraction de `DockIconResolver` est positive, mais le matching fenetre vers
  desktop entry reste volumineux dans `DockState`.

Risque:

- Regressions difficiles a isoler sur le premier chargement du dock.
- Ajout de nouveaux etats de fenetre ou actions dock dans un singleton deja
  dense.

Remboursement recommande:

- Extraire les helpers purs de matching/normalisation dans un singleton ou module
  dedie si de nouveaux cas apparaissent.
- Ajouter des tests de donnees pour `resolveDesktopEntryForToplevel`,
  `fallbackWindowKey`, `normalizedDesktopId` et l'ordre final pinned/running.
- Garder `DockState` comme orchestrateur, pas comme collection illimitee de
  heuristiques.

### Surfaces Liquid Glass et fallback local couteux

Fichiers principaux:

- `src/components/ThemedPanelSurface.qml`
- `src/components/LiquidGlassSurface.qml`
- `src/components/AppLauncherOverlay.qml`
- `src/components/TrayMenuOverlay.qml`
- `src/components/OsdOverlay.qml`

Constat:

- Quand `BackgroundEffect.blurRegion` est actif, `ThemedPanelSurface` desactive
  le backdrop local.
- Quand le blur compositeur n'est pas disponible, `LiquidGlassSurface` utilise
  `ShaderEffectSource` + `MultiEffect` sur un rendu local du wallpaper.

Risque:

- Cout GPU eleve si plusieurs panneaux Liquid Glass utilisent le fallback local.
- Double rendu wallpaper possible si la config utilisateur laisse un wallpaper
  externe actif.
- Le comportement est correct mais doit rester mesure, surtout pour le jeu.

Remboursement recommande:

- Garder les layer-rules niri synchronisees pour toute nouvelle surface blur.
- Mesurer `ffxiv` vs `liquid-glass` avec `docs/PERFORMANCE_TESTS.md`.
- Ne pas multiplier les `LiquidGlassSurface` visibles simultanement sans mesure.

## P2 - Nettoyage et coherence

### Logs tray non gates

Fichiers principaux:

- `src/state/StatusNotchState.qml`
- `src/components/StatusTrayIcon.qml`

Constat:

- Les changements de tray items, sources d'icones, statuts d'image et clics
  souris sont loggues systematiquement.

Risque:

- Logs bruyants en session normale.
- Exposition inutile de titres de fenetres/applications ou d'identifiants tray
  dans les logs utilisateur.

Remboursement recommande:

- Introduire un flag opt-in, par exemple `KAMA_TRACE_TRAY=1`.
- Garder seulement les logs de changement de backend/theme utiles au diagnostic
  general.

### Dependances runtime incompletes ou implicites

Fichiers principaux:

- `PKGBUILD`
- `config/niri/binds.kdl`
- `config/niri/binds.dev.kdl`
- `src/state/OsdState.qml`
- `src/components/AppDock.qml`

Constat:

- `brightnessctl` est appele par `OsdState`.
- `wpctl` est appele par les binds volume.
- `loginctl` est utilise pour l'action quitter.
- Ces outils ne sont pas tous declares explicitement dans le packaging.

Risque:

- Fonctionnalites partiellement cassees apres installation propre.
- Diagnostic difficile car les commandes sont lancees depuis niri ou Quickshell.

Remboursement recommande:

- Declarer les dependances obligatoires et optionnelles dans `PKGBUILD` et la
  documentation niri.
- Ajouter un log clair si `brightnessctl` echoue, avec degradation sans crash.

### Runner historique non niri-only

Fichier principal:

- `run.sh`

Constat:

- `run.sh` contient encore un chemin GNOME -> Hyprland imbrique.

Risque:

- Reintroduction accidentelle de patterns hors cible niri.

Remboursement recommande:

- Decider si `run.sh` est un helper developpeur generique ou un runner niri-only.
  Si niri-only, supprimer le chemin Hyprland imbrique.

### Donnees mockees dans HomePanel

Fichier principal:

- `src/components/HomePanel.qml`

Constat:

- Le panel maison embarque une liste statique de pieces, statuts, volets et
  temperatures.

Risque:

- Le composant ressemble a une feature durable alors que les donnees sont un
  mock.
- Toute integration future Home Assistant devra distinguer UI, etat et backend.

Remboursement recommande:

- Si le panel reste demonstratif, le documenter comme mock.
- Si le panel devient reel, extraire un singleton d'etat dedie et garder
  `HomePanel` purement visuel.

## Dette de tests

Verifications existantes:

- `make check` lance `qmllint` sur les QML, avec exclusion de
  `src/ipc/KamaShellIpc.qml`.
- `make test` ajoute `bash -n`, `py_compile` et la verification `.SRCINFO`.
- `docs/PERFORMANCE_TESTS.md` decrit des mesures manuelles CPU/GPU/frametime.

Manques importants:

- Tests de parsing et normalisation de `ShellConfig`.
- Tests du script `update-kama-config.py`.
- Tests purs de matching dock: pinned, running, fallback labels, app ids et
  desktop ids avec/sans suffixe `.desktop`.
- Tests ou snapshots geometriques du ring pour eviter la divergence entre
  `RingSilhouettePath`, `RingPath` et `RingBlurRegion`.
- Tests de normalisation des evenements `NiriIpc`/`NiriWindowBackend`.
- Verification automatisee que les assets embarques utilisent `Qt.resolvedUrl`.

Priorite recommandee:

1. Ajouter tests Python pour `update-kama-config.py`.
2. Extraire les fonctions pures critiques de config/dock vers des modules
   testables, ou ajouter un harness QML si l'extraction n'est pas justifiee.
3. Ajouter un check statique simple sur les chemins d'assets relatifs dans QML.
4. Ajouter une mesure manuelle documentee apres chaque changement du ring.

## Points sains a preserver

- Les `PanelWindow` multi-ecran utilisent le pattern `Variants {
  model: Quickshell.screens }` avec `required property var modelData`.
- Les namespaces utilisant `BackgroundEffect.blurRegion` ont des layer-rules
  niri avec `background-effect { xray false }` dans la config dev et l'exemple.
- Les process niri passent par `NiriIpc`, avec `SplitParser` pour le stream long.
- Les lecons Pipewire/UPower sont appliquees: `PwNode` type explicitement,
  `audioSink.ready`, pourcentage batterie converti en 0..100.
- `DockIconResolver` isole deja la resolution asynchrone d'icones du dock.
- `ClockState` utilise `SystemClock` au lieu d'un processus externe.

## Ordre de remboursement suggere

1. Corriger les dettes courtes a risque faible: `OsdPanel` + `Qt.resolvedUrl`,
   shortcut documentaire, logs tray gates, dependances runtime.
2. Appliquer la passe performance v1 du ring et mesurer.
3. Clarifier le modele niri des fenetres avant d'ajouter fullscreen retract,
   workspaces ou nouvelles actions dock.
4. Stabiliser `ShellConfig` avec tests avant d'ajouter de nouvelles cles.
5. Refondre progressivement la geometrie du ring autour d'un modele de slots ou
   d'un renderer exact commun.
