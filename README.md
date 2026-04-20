# Glass Shell

Glass Shell est un MVP de shell Linux moderne inspiré de la maquette fournie, construit autour de Hyprland, AGS/Astal, GTK4 et TypeScript. Cette première base fournit un dépôt structuré, un bootstrap AGS exécutable, une navigation entre sections et une UI initiale fidèle à l’intention visuelle avec données mockées.

## Objectifs du MVP

- shell AGS lançable localement
- navigation entre `Dashboard`, `Gaming Universe` et `Dev Universe`
- layout racine avec sidebar, zone centrale, control center et dock
- architecture modulaire prête pour les intégrations système réelles
- documentation d’installation, d’architecture et des limites connues

## Prérequis système

- Linux avec session Wayland
- Hyprland
- `gjs`
- `gtk4`
- `glib2`
- `libastal` / Astal GTK4
- `ags` CLI v2
- `sass` support géré par AGS pour les imports `.scss`

Pour les phases suivantes, il faudra également :

- `NetworkManager`
- `bluez`
- `upower`
- `pipewire` et `wireplumber`
- `brightnessctl`
- `playerctl` optionnel
- `systemd --user`

## Dépendances npm

- `ags`
- `typescript`

## Installation

1. Installer les dépendances système listées ci-dessus.
2. Installer les dépendances du projet :

```bash
npm install
```

3. Générer les types AGS si nécessaire :

```bash
npm run types
```

## Lancement

Mode développement :

```bash
npm run dev
```

Bundle local :

```bash
npm run build
```

## Structure du projet

```text
src/
  app/           bootstrap et composition du shell
  assets/        assets UI futurs
  components/    composants de layout et primitives réutilisables
  config/        configuration et valeurs par défaut
  integrations/  adaptateurs système Linux / D-Bus
  screens/       écrans principaux
  services/      orchestration métier et sources de données
  store/         état global léger
  styles/        tokens, thèmes et layout SCSS
  utils/         helpers transverses
  widgets/       widgets métier
docs/
  architecture.md
  integrations.md
  todo.md
```

## État d’avancement

Phase 0 et début Phase 1 :

- squelette du dépôt créé
- bootstrap AGS/TypeScript ajouté
- layout shell initial inspiré de la maquette
- navigation de base opérationnelle côté UI
- données encore mockées pour les widgets

## Limites connues

- intégrations CPU, RAM, batterie, réseau, audio et luminosité non branchées
- launcher `.desktop` non implémenté
- scans Gaming/Dev non branchés au système de fichiers
- actions session non connectées
- le projet n’a pas encore été validé dans cet environnement faute de dépendances AGS/Astal installées dans le dépôt

## Documentation complémentaire

- [Architecture](docs/architecture.md)
- [Intégrations](docs/integrations.md)
- [Roadmap](docs/todo.md)
