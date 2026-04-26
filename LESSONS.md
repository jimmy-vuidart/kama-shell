# LESSONS.md

## Quickshell / QML

- Le point d'entrée réel du shell est `src/shell.qml`, pas `shell.qml` à la racine. Les scripts et la documentation doivent rester alignés là-dessus.
- Pour une config multi-écran, `Variants { model: Quickshell.screens }` + `required property var modelData` reste le pattern de base le plus propre pour `PanelWindow`.
- Quand un état doit être partagé entre plusieurs fenêtres ou composants répliqués, il faut le sortir dans un `pragma Singleton`. Le dock applicatif fonctionne correctement avec `src/state/DockState.qml` pour cette raison.
- Dans un `Instantiator`, éviter `QtObject` comme delegate si on doit y placer des enfants QML comme `Connections`. Utiliser un `Item` non visuel évite l'erreur runtime `Cannot assign to non-existent default property`.

## Ring / Dock

- Le dock intégré au ring est plus fiable s'il est sculpté dans la géométrie du ring lui-même, au niveau du `mask`, du `blurRegion` et du tracé du cutout intérieur. Superposer une forme de dock indépendante donne vite un rendu de "deux pièces empilées".
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

- `DockState` agrège proprement deux sources:
  - `DesktopEntries` pour les métadonnées applicatives
  - `ToplevelManager.toplevels` pour les fenêtres ouvertes
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

## Débogage

- `make check` avec `qmllint -I src ...` attrape bien les erreurs de syntaxe, mais pas les problèmes d'initialisation runtime liés à Wayland, `DesktopEntries` ou aux timings de chargement.
- Quand Quickshell écrit dans `log.qslog`, le fichier est binaire. Utiliser `strings` pour extraire les messages lisibles.
- Un test `QT_QPA_PLATFORM=offscreen quickshell -p ...` est utile pour valider du QML hors rendu Wayland, mais ne remplace pas un test réel pour `PanelWindow`.
