# Roadmap

## Phase 1 — Prototype UI

- [x] créer la structure du dépôt
- [x] ajouter le bootstrap AGS/TypeScript
- [x] poser le layout principal inspiré de la maquette
- [x] ajouter la navigation entre sections
- [x] ajouter des widgets mockés cohérents
- [ ] raffiner les états actifs, hover et transitions

## Phase 2 — Données système réelles

- [ ] brancher CPU et RAM via `/proc`
- [ ] brancher batterie via UPower
- [ ] brancher réseau via NetworkManager
- [ ] brancher volume via PipeWire / WirePlumber
- [ ] brancher luminosité via `brightnessctl` ou `/sys`
- [ ] remplacer l’horloge mockée par un polling réel

## Phase 3 — Gaming / Dev

- [ ] scanner les `.desktop`
- [ ] détecter Steam, Lutris, Heroic et ProtonUp-Qt
- [ ] afficher une bibliothèque de jeux issue de sources locales
- [ ] scanner les projets de développement configurés
- [ ] ajouter les actions rapides par projet

## Phase 4 — Stabilisation

- [ ] ajouter un chargeur de configuration utilisateur
- [ ] ajouter un système de logs utile
- [ ] gérer les états d’erreur et d’absence de services
- [ ] documenter l’installation détaillée
- [ ] lister les limitations connues et améliorations futures
