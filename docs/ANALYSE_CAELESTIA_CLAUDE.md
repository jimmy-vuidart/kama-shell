# Analyse comparative : Kama Ring ↔ Caelestia Drawers

Comparaison du décor de Kama Shell (`src/components/Ring.qml`) avec le système de drawers de [CaelestiaShell](https://github.com/caelestia-dots/shell), ciblée sur la **gestion du contenu embarqué dans le ring** (clock notch, home panel, dock) et la manière dont la silhouette s'adapte à ce contenu.

Sources consultées :
- `CaelestiaShell/modules/drawers/ContentWindow.qml`
- `CaelestiaShell/modules/drawers/Drawers.qml`, `Panels.qml`, `Regions.qml`, `Exclusions.qml`, `Interactions.qml`
- `CaelestiaShell/modules/bar/Bar.qml`, `BarWrapper.qml`
- `CaelestiaShell/plugin/src/Caelestia/Blobs/` (`blobgroup.*`, `blobrect.*`, `blobinvertedrect.*`, `blobmaterial.*`, `blobshape.*`, `shaders/blob.frag`, `shaders/blob.vert`)
- `CaelestiaShell/plugin/src/Caelestia/Config/barconfig.hpp`
- Côté Kama : `Ring.qml`, `RingSilhouettePath.qml`, `RingBlurRegion.qml`, `RingPath.qml`, `HomePanel.qml`, `ExpandableEdgeWidget.qml`, `ShellGeometry.qml`

## 1. Architecture du décor

| Aspect | Kama (Ring) | Caelestia (Drawers) |
|---|---|---|
| Surfaces Wayland | Plusieurs `PanelWindow` distinctes (`kama-shell-ring` overlay, `kama-shell-wallpaper`, `kama-shell-launcher`, …) | **Une seule** `ContentWindow` plein écran (`WlrLayershell.exclusionMode: Ignore`) qui héberge bar + tous les drawers + popouts ; la zone réservée du compositeur est déclarée dans un objet `Exclusions` séparé |
| Détection des hits | `mask: Region` qui soustrait l'`InnerCutout` du décor et ajoute les bounding boxes interactives du dock et du home panel | `mask: hasFullscreen ? emptyRegion : regions` ; `regions` est calculé centralement par `Regions.qml` à partir du bar et des panels visibles |
| Source de vérité géométrique | **Deux jumeaux à maintenir** : `RingSilhouettePath.qml` (GPU `ShapePath`, ≈100 lignes de `PathLine`/`PathCubic`/`PathArc`) + `RingPath.qml` (CPU scan-line pour `BackgroundEffect.blurRegion`). AGENTS.md insiste sur la synchronisation des deux | **Un seul shader SDF** (`plugin/src/Caelestia/Blobs/shaders/blob.frag`, ≈250 lignes GLSL). Chaque "blob" déclare un rect, le `smin()` smooth-min fusionne tout en une seule SDF cohérente, vue par tous les rendus |
| Blur region | Rasterisation CPU scan-line dans `RingBlurRegion.qml`, dépend exactement de `RingPath.buildInnerSegments` | Implicite : le compositeur applique le blur derrière la fenêtre entière, la fenêtre se masque elle-même via `mask: regions` |
| Couplage widget ↔ silhouette | `Ring.qml` lit ~20 propriétés depuis chaque widget (`dockShapeLeft`, `homePanelShapeTop`, `clockNotchBottom`…) et hardcode 4 sub-paths Bézier pour caver le contour | Chaque drawer est un `BlobRect` enfant du même `BlobGroup`. Le bord se creuse automatiquement autour, sans code par-widget |
| Déclaration des entries | Widgets instanciés en dur dans `Ring.qml` (`DateTimeNotch`, `HomePanel`, `HouseIcon`, `ExpandableEdgeWidget` contenant `AppDock`) | `Config.bar.entries: QVariantList` → `Repeater` + `DelegateChooser` (`logo`, `workspaces`, `clock`, `tray`, `power`, `spacer`, …). Réordonnable depuis la config utilisateur, chaque entry instancie un `WrappedLoader` async gated par `enabled` |
| Déformation du contenu | `revealVelocity = revealTarget - revealProgress` (proxy de vélocité 1D) → `squashBoost` ajouté à la silhouette ; **le contenu du widget n'est pas déformé visuellement** | `BlobRect` simule un ressort physique 2×2 underdamped en C++, suit la vitesse scène-espace de l'élément et produit un `deformMatrix` 4×4 exposé à QML ; le drawer applique ce matrix en `transform: Matrix4x4` → le contenu s'étire avec la bulle |
| Fullscreen | Non géré (le ring reste visible) | `fsTransitionProg` détecté via `HyprlandMonitor.activeWorkspace.toplevels`, ramène `borderThickness`/`borderRounding`/`shadowOpacity` à 0 et fait passer la fenêtre en `WlrLayer.Overlay` au-dessus du fullscreen |
| Drawers/popouts | Pas de notion unifiée (le launcher est sa propre `PanelWindow`) | Tous les panneaux (dashboard, launcher, sidebar, session, OSD, notifications, popouts) co-localisés dans la même `ContentWindow` et fusionnent avec le bar via le même SDF |

## 2. Le coeur de l'écart : comment le contenu pilote la silhouette

### Côté Kama

Le contenu **définit** la silhouette : `Ring.qml` calcule des coordonnées intermédiaires à partir des propriétés des widgets, puis injecte ~20 valeurs dans :
- l'outline GPU (`RingSilhouettePath` en mode fill avec `OddEvenFill`)
- les outlines stroke (2 instances de `RingOutlinePath`)
- l'highlight de notch (un `ShapePath` séparé)
- le mask (`InnerCutout` qui réutilise `RingSilhouettePath`)
- le blur region (`RingBlurRegion` qui consomme les mêmes valeurs côté JS via `RingPath.buildInnerSegments`)

Concrètement, pour ajouter un nouvel élément embarqué (par ex. une notch micro/caméra à gauche, ou un widget média en bas-droite), il faut :
1. Étendre `RingSilhouettePath.qml` avec les nouveaux `PathLine`/`PathCubic`/`PathArc` au bon endroit dans la séquence linéaire des sub-paths.
2. Étendre `RingPath.qml::buildInnerSegments` avec les mêmes segments en JavaScript (`line`/`cubic`/`arc`).
3. Ajouter ~6 readonly properties géométriques sur `Ring.qml` (`window.xxxLeft`, `window.xxxTop`, …).
4. Câbler le widget réel et le faire émettre les bonnes valeurs.
5. Penser au highlight (`ShapePath` séparé), à la duplication outline `panelBorderSupport`/`panelBorder`, à l'`InnerCutout` qui réutilise déjà la même `RingSilhouettePath`, à l'expansion via `revealVelocity` si l'élément est interactif.

Le bénéfice : **contrôle pixel-perfect** du contour, courbes Bézier choisies à la main. Le coût : friction élevée d'évolution, deux jumeaux CPU/GPU à garder synchronisés (callout explicite dans `CLAUDE.md`/`AGENTS.md`).

### Côté Caelestia

La silhouette **se déduit** du contenu via un shader SDF. Le shader (`blob.frag`) reçoit en uniform :
- `invertedOuter` + `invertedInner` + `invertedRadius` : un "anti-rect" qui décrit le frame extérieur (ce qui produit le ring).
- `rectData[80]` : jusqu'à 16 rects de drawer (5 vec4 par rect : centre+demi-extents, propriétés, inverse-deform-matrix, screen-half, radii par coin).
- `smoothFactor` : la distance sur laquelle `smin` lisse les jonctions.

Le pipeline du shader, en trois passes :
1. **Phase 1** — calcule la SDF de chaque rect, applique la déformation physique inverse, applique un *AABB early-out*, retient un `owner` (lequel des rects "possède" le pixel).
2. **Phase 2** — hard-min baseline (`mergedSdf = min(dArr[i])`).
3. **Phase 3** — pour chaque paire de rects non-exclus, `smin(dArr[i], dArr[j], k)` produit une fusion lisse C² continue. Le `exclude` côté QML évite que deux panels adjacents (ex. `utilities` ↔ `sidebar`) ne fusionnent quand on les veut séparés.

Une astuce remarquable : la **"border sinks"** zone à la fin du shader. Quand un `BlobRect` est proche du bord du frame, le shader pousse le bord intérieur vers l'extérieur **uniquement dans la zone latérale du rect** (`topPen`, `botPen`, `leftPen`, `rightPen` clampés à `innerTop - outerTop`). Résultat : la bulle qui héberge le drawer "creuse" le bord intérieur **tout en gardant la même épaisseur** au-dessus de la bulle. C'est exactement le comportement visuel qu'on essaie d'obtenir manuellement avec les `PathCubic` du dock bump dans Kama, mais ici c'est dérivé géométriquement et marche pour n'importe quel rect.

L'`InvertedRect` est rendu via `smaxSharpA(dOuter, -dInner, k)` : la variante `smaxSharpA` garde le bord extérieur du frame *parfaitement net* (pas de rétrécissement aux coins de l'écran), parce que la pondération `smoothstep(0, k*0.5, -a)` désactive le blend quand on est du côté extérieur du rect outer.

Ajouter un nouveau drawer dans Caelestia se réduit à : ancrer un `BlobRect` sous `panels.dashboard` (ou autre Item parent) dans `ContentWindow.qml`, lui donner son `panel`, son `deformAmount`, son `radius`. Le shader fait le reste. Aucun travail sur la silhouette à proprement parler.

### Côté physique : `BlobRect::updatePhysics`

Caelestia ajoute une couche que Kama n'a pas : chaque `BlobRect` mesure sa vitesse scène-espace (`mapToScene` au centre, delta sur `dt`), calcule un *target* `R(θ) · diag(stretch, compress) · R(θ)^T` orienté dans la direction du mouvement, et fait converger trois composantes (`m_dm00`, `m_dm01`, `m_dm11`) vers cette cible par ressort underdamped (`kStiffness`, `kDamping`). Le `deformMatrix` résultant est :
- envoyé au shader comme inverse-deform-matrix (le SDF est évalué dans l'espace pré-déformation pour que le rect "garde la même forme physique")
- exposé à QML pour que le drawer applique le **même** matrix sur son contenu (`transform: Matrix4x4 { matrix: dashBg.deformMatrix }`)

Visuellement, le bord et le contenu s'étirent ensemble. C'est l'effet "liquide" de Caelestia.

Kama a quelque chose d'analogue en plus simple : `revealVelocity` est un proxy 1D (cible - courant) qui décroît automatiquement vers 0 quand le ressort QML se stabilise. Mais il n'est appliqué qu'à la silhouette, pas au contenu, et il n'a pas de notion de direction de mouvement scène-espace.

## 3. Le pattern "bar entries" côté Caelestia

Au-delà du SDF, il y a un second pattern intéressant : **le contenu du bar est piloté par config**, pas par QML.

`barconfig.hpp` :
```cpp
CONFIG_PROPERTY(QVariantList, entries,
    {
        vmap({ { u"id"_s, u"logo"_s }, { u"enabled"_s, true } }),
        vmap({ { u"id"_s, u"workspaces"_s }, { u"enabled"_s, true } }),
        vmap({ { u"id"_s, u"spacer"_s }, { u"enabled"_s, true } }),
        vmap({ { u"id"_s, u"activeWindow"_s }, { u"enabled"_s, true } }),
        // …
    })
```

`Bar.qml` :
```qml
Repeater {
    model: Config.bar.entries
    DelegateChooser {
        role: "id"
        DelegateChoice { roleValue: "spacer"; delegate: WrappedLoader { Layout.fillHeight: enabled } }
        DelegateChoice { roleValue: "logo"; delegate: WrappedLoader { sourceComponent: OsIcon {} } }
        DelegateChoice { roleValue: "workspaces"; delegate: WrappedLoader { sourceComponent: Workspaces { … } } }
        // …
    }
}
```

`WrappedLoader` est `asynchronous: true`, masqué quand `enabled === false`, et porte des margins `Layout.topMargin`/`bottomMargin` calculés en cherchant le premier et le dernier loader actif (donc le padding ne devient pas faux quand on désactive un widget extrême).

Le bénéfice : un utilisateur réordonne / désactive / duplique les entries depuis `~/.config/caelestia` sans toucher au code QML. Kama hardcode aujourd'hui la présence et la position de `DateTimeNotch`, `HomePanel`, `HouseIcon`, `ExpandableEdgeWidget` dans `Ring.qml`.

## 4. Recommandations classées par ratio impact/effort

### Priorité 1 — modèle déclaratif de "slots de ring" *(effort modéré, gain immédiat)*

Extraire un singleton `RingSlots.qml` (ou un model dans `ShellGeometry`) qui expose une liste typée :

```qml
[
    { edge: "top",    kind: "notch",  position: "center", width, depth, radius, item: dateTimeComponent },
    { edge: "right",  kind: "panel",  y, w, h, radius,                     item: homePanelComponent },
    { edge: "bottom", kind: "bump",   position: "center", w, h, curveRun,  item: dockComponent }
]
```

`RingSilhouettePath` et `RingPath` itèrent dessus et **génèrent dynamiquement** les sub-paths (chaque `kind` mappe sur une recette de segments). `Ring.qml` ne calcule plus 20 readonly properties géométriques par widget : il instancie les widgets via un Repeater positionné depuis le même modèle.

Bénéfices :
- Ajouter un slot = ajouter une entrée. Plus de touch dans 3 fichiers.
- Le modèle peut être lu depuis `kama.conf` (`ring.slots`), ce qui aligne Kama sur le pattern Caelestia sans nécessiter un plugin C++.
- Le hot-reload de Quickshell devient utilisable pour prototyper des layouts.

Coût : le générateur de segments doit couvrir 3-4 "kinds" géométriques (rect notch, panel cutout, bump cubic, slot circulaire). Les deux jumeaux (GPU `ShapePath` et CPU `RingPath`) restent à maintenir, mais leur logique se factorise dans un petit moteur.

### Priorité 2 — étendre la déformation au contenu *(effort faible)*

Aujourd'hui `revealVelocity` n'agit que sur le contour. Appliquer un `transform: Scale { … }` (ou un `Matrix4x4` non-uniforme) **sur le contenu** du widget en utilisant la même quantité produit l'effet "liquide" qui fait le charme de Caelestia. Pour `HomePanel`, ça veut dire scaler horizontalement par `1 + revealVelocity * 0.04` autour du bord droit ; pour le dock, scaler verticalement.

Coût : très faible — pas d'archi, juste un `transform:` par widget. Gain visuel disproportionné.

### Priorité 3 — retract en fullscreen *(effort faible)*

`NiriWorkspaceState` connaît déjà la fenêtre focus. Exposer `hasFullscreen` (via `windows[].is_fullscreen` ou équivalent niri IPC), animer `frameInset → 0` et `decor opacity → 0` via `Behavior on … { NumberAnimation }`. Évite d'écraser une vidéo plein écran.

Coût : faible, surtout si l'info est déjà dans `NiriWorkspaceState`. À combiner avec un repli de `kama-shell-wallpaper` pour libérer le compositeur de toute composition inutile.

### Priorité 4 — passer à un rendu SDF *(effort lourd, gain architectural)*

Deux variantes :

- **Plugin C++ Quickshell** (à la Caelestia) : ≈400 lignes de C++ + un fragment shader. Build system : il faut intégrer un `CMakeLists.txt` plugin et que les packagers sachent le construire. Forte cohérence avec la qualité de rendu actuelle.
- **`ShaderEffect` QML pur** : on écrit le même fragment shader (≈150 lignes GLSL pour notre cas, plus simple que blob.frag) et on envoie les rects via uniform array depuis QML. Pas de C++, pas de build. Limites : pas d'AABB tree, pas de scene-graph node custom, donc plafond plus bas en perfs si on multiplie les rects (mais on en a 3 actuellement, large marge).

Bénéfices :
- **Le jumeau CPU/GPU disparaît** : `BackgroundEffect.blurRegion` se déduit du même SDF, soit en générant l'`InnerCutout` via `ShaderEffectSource` + `mask: Region { item: … }`, soit en rasterisant le SDF côté CPU une seule fois par changement (et non par frame).
- Les formes complexes futures (multi-notch, drawers latéraux, déformation physique scène-espace) deviennent triviales.
- Les outlines et l'highlight se dérivent du même SDF (échantillonné à `mergedSdf = -1.0`, `-2.0`, …) au lieu d'être trois `ShapePath` redondants.

À tenir en réserve jusqu'à ce que la priorité 1 commence à serrer (par exemple le jour où on veut un quatrième slot, ou un slot animé qui apparaît/disparaît).

### Priorité 5 — unifier les surfaces Wayland *(effort lourd, optionnel)*

Fusionner `Ring` + `AppLauncherOverlay` (et plus tard d'éventuels OSD, notifications) dans une seule `PanelWindow` avec `mask: Region` pour les zones interactives, comme Caelestia. Bénéfices : un seul Z-order, items partageables, IPC visibility simplifiée. Coût : refactor profond qui touche aussi `KamaShellIpc` et `CompositorState`. Justifié si la collection d'overlays grandit ; pas urgent aujourd'hui.

## 5. Recommandation pratique

Commencer par **#1 + #2** :

- #1 (slot model) débloque le hot-reload sur les variations de layout et fait disparaître la friction d'évolution sans toucher au moteur de rendu actuel. C'est aussi la fondation qui rend #4 indolore plus tard.
- #2 (déformation du contenu) donne le côté "liquide" de Caelestia pour un coût trivial.

#3 (fullscreen retract) est un quick-win UX indépendant qu'on peut faire à tout moment.

#4 (SDF) attend que le slot model existe : refaire un rendu SDF sur l'archi actuelle serait peine perdue tant que les segments sont décrits à la main. Avec le slot model en place, le SDF devient juste "une autre cible de rendu" qui consomme le même modèle.

#5 (surface unifiée) attend que le besoin se manifeste (au moins un troisième overlay multi-écran à intégrer).
