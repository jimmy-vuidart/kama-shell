# AGENTS.md

Ce dépôt contient une configuration Quickshell minimale, actuellement centrée sur [`src/shell.qml`](/mnt/d/Projets/kama-shell/src/shell.qml). Les changements doivent rester compatibles avec Quickshell et avec un usage Wayland via `PanelWindow` + `WlrLayershell`.

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
- `src/components/Ring.qml`: `PanelWindow` multi-écran et géométrie du ring
- `src/components/AppDock.qml`: layout visuel du dock
- `src/state/ShellConfig.qml`: configuration utilisateur lue depuis `~/.config/kama-shell/kama.conf`
- `src/state/ShellTheme.qml`: thème visuel actif, actuellement `glassmorphism` et futur `ffxiv`
- `src/state/ShellGeometry.qml`: constantes de forme partagées entre ring et dock
- `src/state/DockState.qml`: état global du dock, apps pinned + running via `DesktopEntries` et `ToplevelManager`

Pour le dock applicatif:

- garder la séparation nette entre état (`DockState`) et rendu (`AppDock`, `AppDockItem`)
- préférer `DesktopEntries` pour les métadonnées applicatives
- préférer `ToplevelManager` pour les fenêtres ouvertes tant que le compositeur expose correctement les toplevels
- éviter d'introduire de nouveaux fallbacks spécifiques à une application si un fallback générique de résolution d'icônes suffit

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
