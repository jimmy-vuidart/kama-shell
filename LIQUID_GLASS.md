# Liquid Glass — plan d'implémentation

Objectif: ajouter un thème visuel `liquid-glass` qui se rapproche du rendu d'iOS 26
(translucidité forte, backdrop blur saturé, voile clair, edge highlight, ombre douce),
sans casser `glassmorphism` ni `ffxiv`.

Le socle wallpaper (`WallpaperWindow` + `WallpaperState`) est déjà en place et sert
de source visuelle aux surfaces.

## Architecture cible

```
ShellConfig.visualTheme === "liquid-glass"
        │
        ▼
ShellTheme  ──►  expose des tokens visuels (alpha, radius, etc.)
        │
        ▼
ThemedPanelSurface (existant)
   ├── thème glassmorphism / ffxiv → rendu actuel par dégradé
   └── thème liquid-glass         → délègue à LiquidGlassSurface
                                       │
                                       ├── Image privée (source = WallpaperState.source)
                                       │   recadrée via mapToItem sur la zone du panel
                                       ├── ShaderEffectSource (capture de l'Image)
                                       ├── MultiEffect (blur + saturation + brightness)
                                       ├── voile blanc très clair
                                       ├── inner stroke clair + outer stroke sombre
                                       └── RectangularShadow
```

Contrainte Wayland: chaque `PanelWindow` est une surface séparée. `ShaderEffectSource`
ne peut pas capturer un Item d'une autre fenêtre. Donc chaque `LiquidGlassSurface`
charge **sa propre Image** à partir de `WallpaperState.source` et la repositionne
en interne pour que le crop visible corresponde à ce qu'il y a sous le panel.

## Phase 1 — socle thème (sans shader custom)

Suffit pour ~80% du rendu Apple perçu.

1. **`ShellConfig.qml`**
   - Ajouter `"liquid-glass"` à `supportedVisualThemes`.
   - Mapper l'alias `"liquid"` dans `normalizedVisualTheme`.

2. **`ShellTheme.qml`**
   - Ajouter `liquidGlassTheme: "liquid-glass"` + `isLiquidGlass`.
   - Étendre `themeValues` avec un bloc `liquidGlass`. Cibles:
     - `glassTintAlpha: 0.06`
     - `glassTopHighlightAlpha: 0.22`
     - `glassBottomShadeAlpha: 0.08`
     - `glassBorderAlpha: 0.25`
     - `glassInnerHighlightAlpha: 0.55`
   - Nouvelles propriétés dédiées au liquid glass (à ajouter, non utilisées par les
     autres thèmes):
     - `liquidBlurAmount: 0.7` (0–1, mappé vers `MultiEffect.blur`)
     - `liquidBlurMax: 64`
     - `liquidSaturation: 0.22`
     - `liquidBrightness: 0.06`
     - `liquidEdgeHighlightAlpha: 0.55`
     - `liquidEdgeShadowAlpha: 0.18`
     - `liquidShadowBlur: 40`
     - `liquidShadowOffsetY: 12`
     - `liquidShadowAlpha: 0.28`
   - Override `panelRadius: 32`, `panelPadding: 18`.

3. **`src/components/LiquidGlassSurface.qml` (nouveau)**
   - Item avec `default property alias contentData`, `radius`, `padding`,
     `clipContent` — même API publique que `ThemedPanelSurface`.
   - Layout interne, du fond vers le haut:
     1. `Image { id: backdrop; source: WallpaperState.source; ... }` invisible,
        positionné de sorte que `(0,0)` du backdrop tombe sur l'origine de l'écran
        contenant la surface. Calcul: `backdrop.x = -surface.mapToItem(window.contentItem, 0, 0).x`,
        idem pour `y`. Taille = `Screen.width × Screen.height`. `fillMode: PreserveAspectCrop`.
     2. `ShaderEffectSource { sourceItem: backdrop; sourceRect: Qt.rect(...) }`
        avec `sourceRect` limité à la zone du panel (perf).
     3. `MultiEffect` avec `blurEnabled: true`, `blurMax: liquidBlurMax`,
        `blur: liquidBlurAmount`, `saturation: liquidSaturation`,
        `brightness: liquidBrightness`, `autoPaddingEnabled: false`. Masqué par
        `OpacityMask` ou `layer.effect` pour respecter `radius`.
     4. `Rectangle` voile semi-transparent (tint depuis `panelFillUpper`).
     5. `Rectangle` border outer + `Rectangle` border inner highlight.
     6. `RectangularShadow` (ou `MultiEffect.shadowEnabled`) en frère externe.

4. **`ThemedPanelSurface.qml`**
   - Déléguer à `LiquidGlassSurface` quand `ShellTheme.isLiquidGlass`, par exemple
     via un `Loader` qui choisit le composant. Garder le rendu actuel sinon.
   - Ne pas dupliquer la logique des thèmes existants.

5. **`config/kama.conf.example`**
   - Lister `liquid-glass` parmi les thèmes supportés dans le commentaire.

6. **`AGENTS.md`**
   - Ajouter `LiquidGlassSurface.qml` à la "Structure actuelle".
   - Mentionner le nouveau thème dans la liste.

### Vérification phase 1

- Reload Quickshell, basculer `theme = liquid-glass` dans la conf.
- Le wallpaper sous chaque panel doit apparaître flouté + saturé.
- Bordure claire visible en haut, ombre douce sous le panel.
- Pas de flicker au changement de thème (live reload).
- Sur multi-écran: le crop doit suivre l'écran, pas afficher le wallpaper du
  premier moniteur partout.

## Phase 2 — lensing et aberration chromatique ✅

État: implémentée.

7. **Shader fragment GLSL** dans `src/shaders/liquid_glass.frag`:
   - Reçoit la texture du backdrop blurré (binding `source` injecté par
     `Item.layer.effect`) et la taille de la surface (`surfaceSize`,
     `cornerRadius`).
   - Calcule la SDF du rectangle arrondi, `mask = 1 - smoothstep(-1, 0, d)`.
   - `edgeFactor = 1 - smoothstep(0, edgeWidth, distInside)`.
   - Normale par gradient numérique de la SDF.
   - Offset UV: `-normal * lensingStrength * edgeFactor / size` (compression
     vers l'intérieur, comme une lentille).
   - Aberration chromatique: échantillonne R/G/B avec
     `±normal * aberrationStrength * edgeFactor`.
   - Compilé avec `qsb --qt6` via `make shaders`.

8. **`LiquidGlassSurface.qml`**
   - Le `MultiEffect` qui floute le backdrop est dans un `Item` avec
     `layer.enabled: true` et `layer.effect: ShaderEffect { ... }`. Le shader
     reçoit la capture du blur en `source` et applique lensing + aberration.
   - Le rectangle de masque arrondi a disparu: la rondeur est gérée
     directement par la SDF du shader (anti-aliasing inclus).
   - Tokens exposés via `ShellTheme`: `liquidLensingStrength`,
     `liquidEdgeWidth`, `liquidAberrationStrength`. Ajustables sans
     recompilation du shader.

### Vérification phase 2

- Le bord du panel déforme légèrement le wallpaper sous-jacent (lensing visible
  surtout au-dessus de zones contrastées).
- Légère frange colorée sur le bord. Doit rester subtile, pas distrayante.
- Performance: rester >= 60 FPS sur un panel statique. Si chute, baisser
  `blurMax` ou `sourceRect`.
- Après modification du `.frag`, exécuter `make shaders` pour régénérer le
  `.qsb` que charge `ShaderEffect.fragmentShader`.

## Phase 3 — interactivité optionnelle

À considérer seulement si la phase 2 tient la perf et est jolie.

9. **Specular highlight mobile**
   - `RadialGradient` ou `ConicalGradient` en haut, dont le centre suit
     `HoverHandler.point` ou un fake "tilt" basé sur la position curseur global.

10. **Fluid shrink/expand**
    - Animation de `radius` et `width` quand le contenu passe en mode compact
      (équivalent du tab bar qui se contracte au scroll iOS 26). Suppose un
      hook depuis `DockState`/`HomePanel`.

## Risques connus

- **`MultiEffect` + `clip`/`radius`**: l'effet ne respecte pas nativement les
  coins arrondis. Solution: `layer.enabled: true` + `layer.effect: OpacityMask`
  ou un mask `Rectangle` séparé. À tester tôt en phase 1.
- **Performance multi-écran**: chaque panel charge une copie du wallpaper. Avec
  `cache: true` Qt mutualise la texture, mais surveiller la VRAM si > 4K.
- **Reload du wallpaper**: si l'utilisateur change `appearance.wallpaper` à
  chaud, toutes les surfaces doivent recharger. C'est déjà géré via le binding
  sur `WallpaperState.source`.
- **`sourceRect` négatif**: si la surface est partiellement hors écran (ce qui
  ne devrait pas arriver avec les `PanelWindow`), `mapToItem` peut retourner
  des coordonnées négatives. Clamp à `[0, screen.width/height]`.

## Hors scope

- Effet "magnétique" entre éléments Liquid Glass (les iOS 26 controls qui
  fusionnent). Coût d'implémentation très élevé pour un gain visuel marginal
  dans ce shell.
- Adaptation automatique clair/sombre selon le wallpaper. Apple le fait via une
  analyse de luminance. Reportable à une phase 4 si besoin.

## Ordre d'attaque suggéré

1. Phase 1 étapes 1–4 (thème + LiquidGlassSurface basique).
2. Activer le thème, regarder le rendu, ajuster les tokens.
3. Phase 1 étapes 5–6 (doc).
4. Décider si la phase 2 vaut le coût.
