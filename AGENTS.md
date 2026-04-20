# AGENTS.md

## Project overview

This repository contains a small `Quickshell` UI shell focused on rendering a full-screen decorative frame with these characteristics:

- A black frame surrounding the whole screen.
- A transparent center area.
- Rounded **inner** corners (the cutout is rounded, outer screen corners remain square).
- Center click-through behavior using a `Region` mask subtraction.
- A left-side wireless icon dock positioned around two-thirds down the frame height that reveals a hover subpanel fused to the frame, using the same frame color, right outer rounded corners, a rounded top link corner connecting frame→panel, and a layered border/content style inspired by `caelestia-dots`.

Current key files:

- `shell.qml`: Main entry point creating one `PanelWindow` per screen.
- `Frame.qml`: Reusable frame component responsible for visual rendering, bottom-left wireless UI (icon dock + hover subpanel), and exposing the center cutout item used by masking.
- `components/frame/FrameBackground.qml`: Dedicated frame visual renderer (full-screen frame + rounded inner cutout draw logic).
- `components/wireless/WirelessDock.qml`: Left-side wireless icon dock trigger.
- `components/wireless/WirelessState.qml`: Lightweight wireless state provider used by `Frame.qml` to feed panel content.
- `components/wirelessPanel/WirelessPanelShape.qml`: Dedicated visual shape renderer for the wireless panel surface and border.
- `components/wirelessPanel/WirelessPanelContent.qml`: Dedicated content renderer for wireless labels/toggle/device count.
- `wsl.sh`: Robust launcher for WSLg that prioritizes the real WSLg parent socket (`/mnt/wslg/runtime-dir/wayland-0`) to avoid nested-socket loops, resolves runtime/socket access, starts Hyprland in nested Wayland mode, detects the child Wayland socket dynamically, and then launches Quickshell with diagnostics/log paths.
- `README-WSL.md`: Documentation for installation/setup on ArchLinux WSL, including nested Hyprland execution flow and troubleshooting from generated logs.
- `mockup/screenshot.png`: Visual reference for intended appearance.

## Architecture notes

- `shell.qml` uses `Variants { model: Quickshell.screens }` to instantiate the frame on each display.
- `PanelWindow` is anchored on all sides to span the full screen.
- The window `mask` includes the full frame region and subtracts the center cutout region from `Frame.qml`.
- `Frame.qml` owns frame-level composition/wiring: frame drawing, wireless dock + panel placement, panel open state, panel theming props, and `centerCutoutItem` mask alias.
- `WirelessPanel.qml` composes `components/wirelessPanel/WirelessPanelShape.qml` and `components/wirelessPanel/WirelessPanelContent.qml` while exposing hover state used by `Frame.qml`, and reserves top headroom so the rounded top link corner is fully visible.
- `components/wirelessPanel/WirelessPanelShape.qml` owns the emergent panel silhouette (including the rounded top link corner) and layered stroke treatment (outer border + subtle inner line) to keep the panel visually attached to the frame.
- `components/wirelessPanel/WirelessPanelContent.qml` owns the inspired control layout (title, state rows with switches, and settings pill action).
- QML subcomponents are organized in feature folders under `components/` and imported explicitly with local directory imports.

## Working agreement for agents

When making changes in this repository, keep behavior aligned with the current intent:

1. Preserve transparent and click-through center behavior unless explicitly requested otherwise.
2. Preserve rounded inner corners (not rounded outer corners) unless explicitly requested otherwise.
3. Keep `Frame.qml` as the reusable frame component (avoid inlining frame drawing back into `shell.qml`).
4. Keep modifications minimal and consistent with existing QML style.
5. Keep wireless controls visually attached to the frame (shared-border, emerging look), with panel color matching the frame, right outer rounded corners, a rounded top link corner between frame and panel, layered border treatment, and compact state/toggle rows + settings pill action, triggered by hover on the left-side wireless icon dock positioned around two-thirds down the frame unless explicitly requested otherwise.
6. Prefer splitting UI logic into small QML subcomponents early and often to keep each file simple and maintainable.
7. Prefer state/data providers (e.g. `QtObject` components) to keep presentation components focused on rendering.

## Keep this file updated

Every time project behavior or structure changes, update this `AGENTS.md` in the same change set.

At minimum, refresh:

- File/component responsibilities.
- Visual/interaction guarantees (frame thickness, corner behavior, transparency, click-through).
- Any new constraints or conventions introduced for future contributors/agents.
- Keep component boundaries clear by extracting dense sections into focused subcomponents when features grow.

If a change intentionally breaks a previously documented guarantee, explicitly document that guarantee as changed and why.