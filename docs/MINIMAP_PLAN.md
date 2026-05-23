# Plan: minimap de fenetres niri dans le dock

## Resume

Ajouter une minimap en rectangles simples dans le dock, entre les applications
ouvertes et les boutons `Parametres` / `Quitter`.

Decisions verrouillees:

- Portee: fenetres du workspace actif sur l'ecran du dock.
- Action: clic sur un rectangle = focus de la fenetre niri.
- Format: large adaptatif, avec largeur qui grandit selon les colonnes visibles.
- Contenu: rectangles geometriques uniquement, sans miniature ni capture de
  contenu.

## Changements cles

### Modele de fenetres niri

Etendre `NiriWindowBackend` comme source unique:

- parser `layout.pos_in_scrolling_layout` en `columnIndex` / `tileIndex`;
- parser `layout.tile_pos_in_workspace_view` en champs optionnels, sans en
  dependre pour la v1;
- conserver `tileWidth`, `tileHeight`, `windowWidth`, `windowHeight` et les
  offsets existants;
- gerer l'event `WindowLayoutsChanged` pour mettre a jour les layouts sans
  attendre un refresh complet;
- inclure les nouveaux champs layout dans la signature pour declencher les
  rebuilds utiles.

### Composant visuel

Ajouter `DockWindowMinimap.qml`:

- `required property var screen`;
- filtrer `NiriWindowBackend.windows` par
  `NiriWorkspaceState.activeWorkspaceIdForOutput(screen.name)`;
- grouper les fenetres par `columnIndex`, puis `tileIndex`;
- dessiner uniquement des `Rectangle`;
- fenetre active: `ShellTheme.runningIndicatorActive`;
- fenetres inactives: `ShellTheme.runningIndicator`;
- fenetres sans position de layout: petite colonne de fallback a droite;
- clic rectangle: `NiriWindowBackend.focusWindowById(niriWindowId)`.

### Geometrie

Ajouter des constantes dans `ShellGeometry`:

- hauteur: `dockItemSize`;
- largeur min: `112`;
- largeur max: `420`;
- padding: `6`;
- largeur colonne cible: `18`;
- gap horizontal/vertical: `3`;
- hauteur minimale de rectangle: `6`.

### Integration dock

Integrer la minimap dans `AppDock`:

- ordre visuel: launcher, apps, separateur, minimap, separateur, parametres,
  quitter;
- minimap visible seulement sous niri et quand le workspace cible a au moins
  une fenetre exploitable;
- mettre a jour `contentWidth`, `bumpWidth` et `shapeWidth` via le calcul
  existant du dock;
- ne pas modifier `RingRegions`: la minimap reste dans `dockSlot.contentItem`,
  deja inclus dans le mask interactif.

## Interfaces et documentation

- Pas de nouvelle cle `kama.conf`.
- Pas de nouveau namespace layer-shell.
- Pas de nouvelle methode IPC `kama-shell`.
- Extension compatible de `NiriWindowBackend.windows[].layout`: les champs
  existants restent disponibles, les nouveaux champs sont ajoutes sans
  renommage destructif.
- Mettre a jour `docs/TECH.md`:
  - ajouter `DockWindowMinimap.qml` dans la structure actuelle du dock;
  - documenter que `NiriWindowBackend` conserve les indices colonne/tuile et
    traite `WindowLayoutsChanged`;
  - preciser que la minimap consomme le workspace actif par ecran.
- Ne mettre a jour `docs/LESSONS.md` que si la validation en session revele un
  nouveau piege confirme.

## Tests et validation

Verification statique:

- `rtk make check`
- `rtk make test` si le changement est complet et stable.

Verification manuelle sous niri:

- verifier un dock par ecran, chacun sur son workspace actif;
- ouvrir/fermer des fenetres et verifier la mise a jour live;
- changer de workspace sur un ecran et verifier que la minimap suit cet ecran;
- redimensionner/deplacer des fenetres et verifier `WindowLayoutsChanged`;
- cliquer plusieurs rectangles et verifier le focus niri;
- verifier que le dock/ring grandit proprement avec une minimap large;
- verifier l'absence de minimap cassee hors niri ou sans layout exploitable;
- verifier que le comportement fullscreen existant du ring n'est pas regresse.

## Hypotheses

- niri expose au minimum `pos_in_scrolling_layout` pour les fenetres tuilees.
- `tile_pos_in_workspace_view` peut rester `null`; la v1 utilise donc l'ordre
  colonne/tuile comme base fiable.
- La minimap reste purement geometrique: pas de screencopy, PipeWire,
  thumbnails ou capture de contenu.
