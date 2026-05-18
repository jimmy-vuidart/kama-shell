# Kama Shell performance tests

Ce document décrit une procédure reproductible pour mesurer l'impact CPU, RAM,
GPU et frametime de Kama Shell dans une session niri.

## Objectifs

- Mesurer le coût au repos de `quickshell` et `niri`.
- Mesurer le coût des overlays interactifs, notamment le launcher.
- Vérifier si les thèmes avec blur, en particulier `liquid-glass`, ajoutent une
  charge GPU susceptible d'affecter les jeux.
- Comparer les frametimes d'un jeu avec et sans Kama Shell actif.

## Outils attendus

Sur CachyOS/Arch:

```bash
sudo pacman -S intel-gpu-tools nvtop mangohud lib32-mangohud sysstat perf powertop
```

Optionnel:

```bash
sudo pacman -S goverlay renderdoc apitrace bpftrace
```

`intel_gpu_top` peut demander `CAP_PERFMON`:

```bash
sudo setcap cap_perfmon+ep /usr/bin/intel_gpu_top
getcap /usr/bin/intel_gpu_top
```

## Préparation

Créer un dossier de sortie:

```bash
mkdir -p /tmp/kama-perf
```

Identifier les processus:

```bash
pgrep -af quickshell
pgrep -af niri
```

Dans les commandes ci-dessous, remplacer si besoin les PID calculés par:

```bash
QUICKSHELL_PID="$(pgrep -n quickshell)"
NIRI_PID="$(pgrep -n niri)"
```

Noter le contexte de test dans un fichier texte:

```bash
{
  date
  uname -a
  quickshell --version 2>/dev/null || true
  niri --version 2>/dev/null || true
  echo "KAMA_COMPOSITOR=$KAMA_COMPOSITOR"
  echo "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
} > /tmp/kama-perf/context.txt
```

## Test 1: repos

Laisser la session immobile pendant 60 secondes, sans déplacer la souris.

CPU/RAM:

```bash
pidstat -p "$QUICKSHELL_PID,$NIRI_PID" -r -u 1 60 \
  > /tmp/kama-perf/idle-pidstat.txt
```

GPU Intel:

```bash
intel_gpu_top -J -s 1000 -n 61 -o /tmp/kama-perf/idle-gpu.json
```

Observation interactive:

```bash
nvtop
```

Critères à relever:

- CPU moyen et pics de `quickshell`.
- CPU moyen et pics de `niri`.
- mémoire RSS de `quickshell`.
- occupation GPU Render moyenne et pics.
- présence éventuelle d'activité GPU continue alors que l'écran est immobile.

## Test 2: launcher

Mesurer le coût de l'ouverture, de la recherche et de la fermeture du launcher.

Lancer les mesures:

```bash
pidstat -p "$QUICKSHELL_PID,$NIRI_PID" -r -u 1 90 \
  > /tmp/kama-perf/launcher-pidstat.txt
```

```bash
intel_gpu_top -J -s 1000 -n 91 -o /tmp/kama-perf/launcher-gpu.json
```

Pendant la capture:

1. Ouvrir le launcher avec le bind niri configuré.
2. Taper une recherche.
3. Naviguer dans quelques résultats.
4. Fermer le launcher.
5. Répéter 5 fois.

Critères à relever:

- pics CPU pendant l'ouverture et la recherche.
- pics GPU au moment du blur et du rendu de l'overlay.
- retour à l'activité idle après fermeture.
- absence de fuite mémoire évidente après plusieurs ouvertures.

## Test 3: thème actif

Comparer les thèmes `glassmorphism`, `ffxiv` et `liquid-glass`.

Pour chaque thème:

1. Modifier `~/.config/kama-shell/kama.conf`.
2. Attendre le reload de Quickshell.
3. Refaire le test de repos.
4. Refaire le test launcher.

Exemple:

```ini
[appearance]
theme = liquid-glass
```

Points d'attention:

- `glassmorphism` et `ffxiv` doivent rester légers au repos.
- `liquid-glass` peut activer `BackgroundEffect.blurRegion` sur niri.
- si le blur compositeur est indisponible, les surfaces Liquid Glass peuvent
  utiliser un fallback local plus coûteux (`ShaderEffectSource` + `MultiEffect`).

## Test 4: jeu avec MangoHud

Activer MangoHud sur le jeu. Pour Steam:

```text
mangohud %command%
```

Faire deux passes comparables:

- session normale avec Kama Shell.
- session de référence sans Kama Shell, ou avec les fenêtres Kama Shell arrêtées
  si le protocole de test le permet.

Pendant chaque passe, capturer CPU/RAM/GPU:

```bash
pidstat -p "$QUICKSHELL_PID,$NIRI_PID" -r -u 1 300 \
  > /tmp/kama-perf/game-kama-pidstat.txt
```

```bash
intel_gpu_top -J -s 1000 -n 301 -o /tmp/kama-perf/game-kama-gpu.json
```

Dans MangoHud, relever:

- FPS moyen.
- 1% low si disponible.
- frametime moyen et pics.
- charge GPU.
- charge CPU.
- VRAM/RAM.

Répéter la même scène de jeu, avec la même durée, les mêmes réglages graphiques,
la même résolution et sans changer le profil d'alimentation.

## Interprétation

Kama Shell est probablement acceptable pour le jeu si:

- `quickshell` reste proche de l'idle quand le launcher est fermé.
- l'activité GPU Render de `quickshell` ne reste pas élevée en continu.
- `niri` ne montre pas de hausse importante uniquement due aux layers Kama Shell.
- les frametimes MangoHud restent comparables entre la passe avec Kama Shell et
  la passe de référence.

Un problème de performance est probable si:

- `quickshell` consomme plusieurs pourcents CPU en continu sans interaction.
- `intel_gpu_top` montre une activité Render persistante attribuable à
  `quickshell` ou au compositeur alors que rien ne bouge.
- les pics de frametime apparaissent quand le launcher ou le blur est visible.
- le thème `liquid-glass` dégrade nettement les mesures alors que
  `glassmorphism` ou `ffxiv` ne le font pas.

## Rapport de résultat

Pour chaque test, conserver:

- le thème actif.
- la résolution et le taux de rafraîchissement.
- le mode d'alimentation.
- le type de GPU et le pilote.
- les fichiers `pidstat`.
- les fichiers `intel_gpu_top`.
- une capture ou un log MangoHud pour les tests en jeu.

Nom recommandé:

```text
/tmp/kama-perf/
  context.txt
  idle-pidstat.txt
  idle-gpu.json
  launcher-pidstat.txt
  launcher-gpu.json
  game-kama-pidstat.txt
  game-kama-gpu.json
```
