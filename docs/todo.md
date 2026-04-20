# Roadmap

## Phase 1 — Prototype UI

- [x] créer la structure du dépôt
- [x] ajouter le bootstrap AGS/TypeScript
- [x] poser le layout principal inspiré de la maquette
- [x] ajouter la navigation entre sections
- [x] ajouter des widgets mockés cohérents
- [ ] raffiner les états actifs, hover et transitions

## Phase 2 — Données système réelles

- [x] brancher CPU et RAM via `/proc`
- [x] brancher batterie via UPower avec fallback `/sys`
- [x] brancher réseau via fallback `/sys/class/net`
- [x] brancher volume via `wpctl`
- [x] brancher luminosité via `brightnessctl`
- [x] remplacer l’horloge mockée par un polling réel
- [ ] remplacer le fallback réseau par une intégration NetworkManager plus riche
- [ ] remplacer les états Bluetooth et Wi-Fi par des intégrations DBus robustes

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
