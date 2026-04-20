# LESSONS.md

## 2026-04-21 - Layer-shell input routing for Glass Shell

Context: fixing the bug where apps behind the shell were not interactive, while keeping frame debug handles usable.

Lessons:
- In this shell architecture, a single full-screen layer-shell window with a broad input region easily blocks all apps underneath.
- Putting the whole shell in `Astal.Layer.TOP` is not enough; input must be constrained explicitly with `Gdk.Surface.set_input_region(...)`.
- `canTarget={false}` only affects GTK widget hit testing. It does not make a layer-shell surface click-through on Wayland by itself.
- For Wayland layer-shell surfaces, pointer/touch pass-through is controlled by the surface input region, not by keyboard mode.
- A separate `TOP` frame/debug window can make pointer routing harder to reason about. Merging related interactive overlays into one `TOP` window simplified debugging and restored red-point dragging.
- The central `Gaming/Dev` stage should not live in the same interactive `TOP` surface as shell chrome if apps must stay clickable/visible behind it.
- The stable split for this project is:
  - `TOP` window: frame, debug handles, header, sidebar, dock
  - `BOTTOM` window: central stage visuals only
- When only some shell areas must be interactive, define a narrow input region for those areas only instead of toggling entire containers between targetable and non-targetable.
- Diagnostic click handlers are useful, but they should be removed once the issue is understood and resolved.
