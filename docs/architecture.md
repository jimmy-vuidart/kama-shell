# Architecture

## Cible

Le shell est structuré pour séparer strictement :

- la composition UI GTK4/AGS
- l’état et la navigation
- l’orchestration métier
- l’accès système et D-Bus

## Arborescence initiale

```text
src/
  app/
    shell.tsx
  components/
    dock.tsx
    header.tsx
    sidebar.tsx
    primitives/
      card.tsx
      section-title.tsx
      status-chip.tsx
  config/
    defaults.ts
  integrations/
    README.md
  screens/
    dashboard.tsx
    dev.tsx
    gaming.tsx
  services/
    mock-data.ts
  store/
    navigation.ts
  styles/
    main.scss
  utils/
    format.ts
  widgets/
    control-center.tsx
    game-library.tsx
    project-list.tsx
    system-summary.tsx
```

## Modules à créer en premier

1. `Shell Core`
   Initialise AGS, charge les styles, compose la fenêtre principale et le routage de sections.
2. `Navigation Store`
   Définit les sections, labels et métadonnées de navigation.
3. `Mock Data Service`
   Fournit des données réalistes tant que les intégrations système ne sont pas branchées.
4. `System Metrics Service`
   Remplacera progressivement les mocks par des adaptateurs `/proc`, `/sys`, UPower et NetworkManager.
5. `Launcher / Gaming / Dev Services`
   Orchestrent le scan des applications, jeux et projets locaux.

## Décisions de conception

- MVP basé sur une seule fenêtre shell couvrant l’écran, avec zones de layout clairement séparées.
- Styles via un unique point d’entrée SCSS pour garder des tokens visuels cohérents dès le départ.
- Navigation centralisée par identifiants de section pour faciliter l’ajout futur de routing plus riche.
- Services métier découplés des widgets pour permettre des fallbacks propres.

## Extension prévue

- remplacement des mocks par des stores réactifs branchés sur de vraies sources
- ajout d’un service de configuration utilisateur
- ajout d’un système de logs applicatifs
- découpage des thèmes par couches `tokens`, `layout`, `components`, `screens`
