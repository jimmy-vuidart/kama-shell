# Performance: ring opening animations

Ce document sert de plan d'execution pour reprendre l'optimisation des
animations d'ouverture du dock et du panel maison.

## Contexte

Probleme observe: quand le CPU est charge, les animations d'ouverture des
panneaux ralentissent fortement. Le symptome est surtout visible sur le ring:
le dock et le panel maison animent leur ouverture, et la silhouette du ring,
son mask et son blur suivent cette geometrie.

Etat actuel du code:

- `ExpandableEdgeWidget.qml` et `HomePanel.qml` pilotent `revealProgress`.
- `RingPanels.qml` transmet ce `revealProgress` a `RingSlotModel.qml`.
- `RingSlotModel.qml` expose un modele `ringGeometry` consomme par le rendu,
  le mask et le blur.
- `RingShapeSurface.qml` dessine la silhouette visible via `ShapePath` genere
  par `RingPath.buildSvgPath`.
- `RingRegions.qml` reconstruit un mask avec un `Shape` interne base sur le
  meme chemin.
- `RingBlurRegion.qml` reconstruit la region de blur en CPU via
  `RingPath.buildInnerSegments`.

Les tentatives a ne pas reproduire:

- Ne pas snapper une geometrie separee du reveal visible. Cela ameliore le CPU
  mais le ring ne suit plus correctement les notches et les panneaux.
- Ne pas reintroduire un renderer SDF approximatif: l'ancien prototype ne
  matchait pas exactement la silhouette visible et a ete retire.

Patch partiellement en cours au moment de l'ecriture:

- animations passees de `SpringAnimation` a `NumberAnimation` courte;
- suppression du squash base sur `revealVelocity`;
- instrumentation optionnelle `KAMA_TRACE_PERF=1` dans `RingBlurRegion`.

Verifier le `git diff` avant de continuer et ne pas ecraser les changements
existants sans les comprendre.

## Conclusion Caelestia

Le shell concurrent `../CaelestiaShell` utilise deux approches pertinentes:

1. Pour les `Shape` QML secondaires, il definit souvent:
   `preferredRendererType: Shape.CurveRenderer` et parfois `asynchronous: true`.
2. Pour ses drawers principaux, il n'utilise pas une `ShapePath` complexe:
   il rend une union/difference de rectangles arrondis via un plugin C++ QSG
   (`Caelestia.Blobs`) et un shader SDF custom.

Ce point tranche la decision:

- Port direct de `Caelestia.Blobs`: non retenu pour v1. Le ring de Kama n'est
  pas seulement une union de rectangles arrondis; il a une silhouette exacte
  produite par `RingPath.qml`.
- L'ancien `RingSdfSurface` a ete retire: il ne reproduisait pas correctement
  les notches et ajoutait une cible de rendu a maintenir.
- Piste immediate appliquee: garder `ShapePath`, mais demander a Qt d'utiliser
  `Shape.CurveRenderer`, disponible localement avec Qt 6.11.1.

Documentation Qt utile:

- `Shape.preferredRendererType`
- `Shape.CurveRenderer`
- `Shape.asynchronous`

Caelestia montre aussi un pattern d'animation utile: animer une seule propriete
`offsetScale` avec `NumberAnimation`, puis deriver position, opacite et region
interactive depuis cette valeur. Kama peut rester plus simple pour l'instant.

## Plan d'implementation v1

Objectif: ameliorer le cout du rendu anime sans casser la forme exacte.

1. Garder le renderer visible en mode Shape.

   - `RingSurfaceRenderer.qml` reste un wrapper simple vers
     `RingShapeSurface.qml`.
   - Le backend SDF n'existe plus dans le tree.

2. Activer `CurveRenderer` sur la silhouette visible.

   Dans `src/components/RingShapeSurface.qml`, ajouter sur le `Shape` racine:

   ```qml
   preferredRendererType: Shape.CurveRenderer
   asynchronous: true
   ```

   Garder `RingSilhouettePath` branche sur `RingPath.buildSvgPath`.

3. Activer `CurveRenderer` sur le mask du ring.

   Dans `src/components/RingRegions.qml`, dans le `Shape` de
   `component InnerCutout`, ajouter:

   ```qml
   preferredRendererType: Shape.CurveRenderer
   asynchronous: true
   ```

   Le but est d'eviter que la silhouette visible soit optimisee mais que le
   mask garde le chemin de rendu geometrique classique.

4. Garder les animations courtes et predictibles.

   Dans `ExpandableEdgeWidget.qml`:

   - `animationDuration: 120`
   - `Behavior on revealProgress { NumberAnimation { duration: root.animationDuration; easing.type: Easing.OutCubic } }`
   - conserver le clipping d'origine:
     `height: root.expandedHeight * root.revealProgress`

   Dans `HomePanel.qml`:

   - `animationDuration: 150`
   - meme type de `NumberAnimation`.

   Ne pas restaurer `SpringAnimation` tant que le probleme sous charge CPU est
   le sujet principal.

5. Garder le squash desactive pour cette passe.

   Dans `RingPanels.qml`, envoyer:

   ```qml
   dockRevealVelocity: 0
   homeRevealVelocity: 0
   ```

   Et garder les transforms de squash a l'identite:

   ```qml
   xScale: 1
   yScale: 1
   ```

   Raison: le squash ajoute des invalidations de bordure continues pendant
   l'animation. On pourra le reintroduire plus tard si les mesures sont bonnes.

6. Conserver l'instrumentation de `RingBlurRegion`.

   Dans `RingBlurRegion.qml`, garder un mode opt-in:

   ```qml
   readonly property bool tracePerformance: Quickshell.env("KAMA_TRACE_PERF") === "1"
   property int rebuildCount: 0
   ```

   Logguer uniquement quand `KAMA_TRACE_PERF=1`:

   ```qml
   RingBlurRegion rebuild #<n> spans=<count> durationMs=<ms>
   ```

   Ne pas activer cette trace par defaut.

## Plan de verification

Avant tout test:

```bash
rtk git diff --check
rtk pgrep -af quickshell
rtk pgrep -af niri
```

Verification visuelle:

- ouvrir/fermer le dock plusieurs fois;
- ouvrir/fermer le panel maison plusieurs fois;
- verifier que le ring suit exactement les notches;
- verifier que le mask clickable ne cree pas de zones mortes ou de zones
  plein ecran;
- verifier que le rendu reste identique en idle, notamment les coins et les
  notches hautes.

Mesure idle:

```bash
rtk pidstat -p <QUICKSHELL_PID>,<NIRI_PID> -r -u 1 5
```

Mesure pendant interaction:

1. lancer `pidstat`;
2. ouvrir/fermer dock et home panel pendant la capture;
3. noter CPU moyen et pics de `quickshell`.

Trace blur:

Si besoin, relancer Quickshell avec:

```bash
KAMA_TRACE_PERF=1 quickshell -p src/shell.qml
```

Puis ouvrir/fermer les panneaux et verifier:

- nombre de rebuilds `RingBlurRegion`;
- duree en ms des rebuilds;
- absence de rebuilds en boucle quand rien ne bouge.

Critere d'acceptation:

- aucune regression visuelle par rapport au rendu `Shape` exact;
- plus de decalage entre ring, notches et panneaux;
- `rtk git diff --check` OK;
- `quickshell` reste vivant apres hot reload;
- baisse ou stabilisation mesurable des pics CPU pendant ouverture.

## Si v1 ne suffit pas

Si `CurveRenderer` ne suffit pas, ne pas revenir au snap geometrique. Les deux
options suivantes sont les seules directions correctes.

Option A: renderer ring SDF exact.

- Reintroduire un `RingSdfSurface` uniquement s'il consomme le meme modele
  `ringGeometry` que `RingPath.buildInnerSegments`.
- Aligner visuellement avec `RingSilhouettePath` avant d'en faire le defaut.
- Ajouter une etape de build explicite pour le shader compile si cette option
  revient.
- Garder `RingShapeSurface` comme fallback de reference.

Option B: plugin QSG dedie au ring, inspire de Caelestia mais pas copie tel quel.

- Creer un item QML natif qui dessine la silhouette exacte du ring.
- Utiliser une representation ring-specific, pas `BlobRect`, car la forme de
  Kama n'est pas une simple union de rectangles arrondis.
- Exposer uniquement les proprietes geometriques deja produites par
  `RingSlotModel`.

Dans les deux cas, respecter l'invariant du depot: toute evolution de la
geometrie visible doit garder alignes `RingSlotModel`, `RingSilhouettePath`,
`RingPath` et `RingBlurRegion`.
