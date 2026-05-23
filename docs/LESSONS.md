# LESSONS.md

## Quickshell / QML

- Le point d'entrée réel du shell est `src/shell.qml`, pas `shell.qml` à la racine. Les scripts et la documentation doivent rester alignés là-dessus.
- Pour une config multi-écran, `Variants { model: Quickshell.screens }` + `required property var modelData` reste le pattern de base le plus propre pour `PanelWindow`.
- Quand un état doit être partagé entre plusieurs fenêtres ou composants répliqués, il faut le sortir dans un `pragma Singleton`. Le dock applicatif fonctionne correctement avec `src/state/DockState.qml` pour cette raison.
- Dans un `Instantiator`, éviter `QtObject` comme delegate si on doit y placer des enfants QML comme `Connections`. Utiliser un `Item` non visuel évite l'erreur runtime `Cannot assign to non-existent default property`.

## Ring / Dock

- Le dock intégré au ring est plus fiable s'il est sculpté dans la géométrie du ring lui-même, au niveau du `mask` et du tracé du cutout intérieur. Superposer une forme de dock indépendante donne vite un rendu de "deux pièces empilées".
- Le blur compositeur du Ring ne doit jamais être approximé par bandes, rectangles ou régions qui ne partagent pas exactement le `ShapePath` visible. Dans ce dépôt, `src/components/RingBlurRegion.qml` génère la région de blur depuis les mêmes paramètres géométriques que le tracé du Ring, sous forme de spans pixellisés et compressés.
- Les coins bas du ring doivent rester de vrais quarts de cercle, puis le segment inférieur doit rester parfaitement horizontal jusqu'au départ de la bosse du dock.
- Pour une bosse de dock crédible, une géométrie symétrique construite avec deux grandes `PathCubic` miroir donne un meilleur résultat que des `PathArc` ou des segments cassés.
- La largeur visuelle de la bosse ne doit pas être confondue avec la largeur du contenu du dock. Il faut distinguer:
  - la largeur du contenu (`contentWidth`)
  - la largeur du sommet (`bumpWidth`)
  - la largeur totale de la silhouette (`shapeWidth`)
- Pour un widget rétractable réutilisable dans le ring, mieux vaut interpoler une seule géométrie entre deux états:
  - un état compact avec petite bosse centrale (`dockRestWidth`, `dockRestHeight`, `dockRestFlatWidth`)
  - un état ouvert calé sur la vraie taille du widget
- Le pattern le plus robuste pour ce type de panneau est:
  - une petite affordance visible au repos intégrée à la bordure
  - une zone de hover invisible qui descend jusqu'au bas de l'écran
  - une propriété d'animation scalaire unique (`dockReveal`) pilotant à la fois la silhouette du ring et le contenu du widget
- Le contenu visible du widget doit rester dans un conteneur dédié et `clip: true`, séparé de la zone de hover. Cela évite qu'un panneau caché reste cliquable ou déborde visuellement pendant l'animation.
- Pour l'affordance compacte, une mini-icône QML autonome sans fond est préférable à une image externe: elle reste stable au chargement, ne dépend d'aucun thème et peut être repositionnée de quelques pixels pour s'aligner visuellement avec la bosse.
- Quand ce mécanisme sera réutilisé pour d'autres widgets, conserver la même architecture:
  - géométrie compacte dans `ShellGeometry`
  - reveal progress unique
  - hover zone indépendante
  - widget réel animé séparément de son indicateur compact
- Ce pattern doit maintenant passer par un composant dédié, pas être recopié dans chaque fenêtre. Dans ce dépôt, la primitive de base est `src/components/ExpandableEdgeWidget.qml`; `Ring.qml` ne doit garder que la géométrie spécifique du cutout du widget.
- Pour les panels latéraux du même système que `HomePanel`, ne pas créer un `PanelWindow` séparé et ne pas dessiner de `ThemedPanelSurface` propre au panel. Le contenu doit être un composant visuel intégré dans le `PanelWindow` du ring; le fond, la bordure et l'extension doivent venir du tracé du ring.
- Pour qu'un panel intégré se comporte comme le dock, son `revealProgress` doit piloter simultanément:
  - la taille/position du contenu
  - le cutout intérieur du ring
  - les outlines du ring
  - le remplissage du ring
  - l'opacité de l'icône compacte
- L'icône compacte d'un panel intégré doit vivre dans `Ring.qml`, pas dans le composant de contenu. Elle doit utiliser la même taille que l'icône compacte du dock (`dockRestIconSize`) et disparaître pendant l'ouverture.
- Si un panel intégré doit réagir au survol, ajouter explicitement sa zone au `mask` du `PanelWindow` du ring, comme pour `dockWidget.contentItem` et `dockWidget.hoverItem`; sinon Wayland peut ne pas transmettre les événements pointeur à cette zone.

## État du dock

- `DockState` doit rester l'orchestrateur du dock et déléguer les traitements asynchrones dédiés à des singletons séparés, comme `DockIconResolver`.
- `DockState` agrège proprement ces sources:
  - `DesktopEntries` pour les métadonnées applicatives
  - `ToplevelManager.toplevels` pour les fenêtres ouvertes (source unique sous niri)
  - si `ToplevelManager` manque un champ utile, ajouter un backend dedié basé sur `NiriIpc` plutôt que de retomber sur un service tiers
- L'ordre attendu du dock est:
  - pinned
  - séparateur conditionnel
  - running non pinned
- Une app pinned et lancée doit rester un seul item, enrichi avec `isRunning`, `isActive`, `windowCount` et `windows`.
- Pour les apps pinned, la résolution de `DesktopEntry` doit tolérer les deux formes d'identifiant:
  - `foo`
  - `foo.desktop`

## Icônes applicatives

- `DesktopEntry.icon` fournit un nom ou un chemin, mais pas forcément une URL directement exploitable.
- `Quickshell.iconPath()` est la voie normale, mais il peut renvoyer vide si le thème d'icônes Qt/Quickshell n'est pas correctement résolu au démarrage.
- Le thème d'icônes peut être forcé explicitement via `//@ pragma IconTheme ...` au début de `src/shell.qml`.
- Le premier chargement du dock peut arriver avant que `DesktopEntries` soit complètement prêt. Il faut écouter `DesktopEntries.applicationsChanged()` et replanifier un rebuild.
- La résolution d'icônes doit rester générique. Éviter les fallbacks spécifiques à une application si un lookup standard basé sur `DesktopEntry.icon` et les emplacements freedesktop suffit.
- Si un lookup asynchrone de chemin est utilisé, ne garder qu'un seul résultat exploitable. Concaténer plusieurs chemins dans une seule `Image.source` produit une URL invalide et donc aucune icône.
- `Image` standard est plus adapté qu'`IconImage` pour afficher des chemins `file://...` explicites.

## Niri / Compositeur

- Si `qs log` affiche `No shell integration named "layer-shell" found`, Quickshell tombe en `QT_QPA_PLATFORM=xcb` et niri voit le shell comme des `xdg-toplevel`. Installer `layer-shell-qt` et verifier que la session exporte `QT_QPA_PLATFORM=wayland` + `QT_WAYLAND_SHELL_INTEGRATION=layer-shell`.
- Une surface permanente sur `WlrLayer.Overlay` reste au-dessus des fenêtres fullscreen dans niri. Pour un décor de shell qui doit disparaître pendant les jeux/vidéos plein écran, utiliser `WlrLayer.Top`; vider aussi le `mask`/`BackgroundEffect.blurRegion` seulement quand l'IPC expose un état fullscreen explicite.
- Ne pas traiter `layout.window_size == taille output` comme un signal fullscreen niri: après une sortie de fullscreen, certaines apps peuvent garder une géométrie pleine taille et le shell resterait masqué jusqu'à fermeture de l'app.
- Tout `PanelWindow` qui utilise `BackgroundEffect.blurRegion` doit avoir une `layer-rule` niri avec `background-effect { xray false }` dans **les deux** configs (`config/niri/config.kdl` et `config/niri/config.kdl.example`), dans le même patch que le composant. Sans cette règle, niri applique `xray true` par défaut et ne composite que le wallpaper comme source de blur — les fenêtres derrière ne sont pas visibles à travers la surface, même si le côté QML est correctement câblé.
- Le namespace de chaque nouvelle surface doit aussi être ajouté dans le commentaire de la section layer-rules de `config.kdl.example`.
- Les menus natifs Qt (`QMenu`) ouverts depuis le `SystemTray` deviennent des `xdg-toplevel` sous niri/layer-shell et se comportent mal avec les surfaces du shell. Le tray de Kama rend donc ses menus en QML via `TrayMenuOverlay`, `TrayMenuPanel` et `TrayMenuState` au lieu de déléguer à Qt.

## Processus / IO

- `StdioCollector` accumule le texte entre les runs successifs d'un même objet `Process` réutilisé. Si on parse `text` dans `onStreamFinished` après plusieurs runs, on obtient l'accumulation de toutes les sorties passées, pas seulement la dernière. Deux solutions : utiliser `SplitParser` avec `onRead` (fire ligne par ligne, pas d'accumulation entre runs — pattern de `NiriIpc.eventStreamProcess`) ou créer un nouvel objet `Process` dynamiquement et appeler `destroy()` après usage (pattern de `DockIconResolver`).

## Pipewire / UPower

- `UPowerDevice.percentage` expose une valeur `double` dans la plage **0..1** (pas 0..100). Multiplier par 100 avant de comparer à des seuils en pourcentage. Confirmé par les usages dans Caelestia (`percentage * 100`).
- `PwNode.audio` est déclaré `isPropertyConstant` dans les qmltypes Quickshell : la valeur du pointeur ne change jamais après construction. Si le node n'est pas encore `ready` au premier passage, `audio` peut être `null` et le binding QML ne verra jamais la mise à jour (aucun signal `audioChanged` ne sera émis). Inclure `audioSink.ready` dans la condition `hasAudio` pour forcer une réévaluation dès que le node est prêt.
- Typer `audioSink` comme `PwNode` (au lieu de `var`) permet à QML d'établir correctement les connexions de signaux sur les propriétés imbriquées (`audio.muted` → `mutedChanged`, `audio.volume` → `volumesChanged`). Avec `var`, QML utilise la résolution dynamique et peut manquer certains signaux.
- `PwNodeAudio.volume` est un float linéaire brut, plage `0..∞` (1.0 = 100 %, la suramplification dépasse 1.0). Les seuils d'icône doivent être définis sur cette échelle, pas en pourcentage.

## Assets et URLs dans Quickshell

- Quickshell charge les composants QML via le scheme `qs:@` (visible dans les logs d'intercepteur). Sous ce scheme, une **string relative concaténée** (`"../assets/" + name`) passée à `Image.source` échoue silencieusement (status `Null`, jamais `Error`) — le fallback rectangle s'affiche sans aucun message d'erreur. Toujours envelopper dans `Qt.resolvedUrl()` pour produire une URL absolue résolue contre la base du fichier QML hôte. Voir `OsdPanel.qml` et `StatusNotch.qml` comme exemples de référence dans ce dépôt.
- Ce piège ne touche que les assets embarqués dans le source tree (SVG, shaders, etc.). Les chemins absolus (`file://…`) et les URLs fournies par des services Quickshell (`Quickshell.iconPath`, `SystemTray.item.icon`) ne sont pas affectés.

## Débogage

- `make check` avec `qmllint -I src ...` attrape bien les erreurs de syntaxe, mais pas les problèmes d'initialisation runtime liés à Wayland, `DesktopEntries` ou aux timings de chargement.
- Quand Quickshell écrit dans `log.qslog`, le fichier est binaire. Utiliser `strings` pour extraire les messages lisibles.
- Un test `QT_QPA_PLATFORM=offscreen quickshell -p ...` est utile pour valider du QML hors rendu Wayland, mais ne remplace pas un test réel pour `PanelWindow`.
