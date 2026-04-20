import { Astal } from "ags/gtk4"
import Gtk from "gi://Gtk?version=4.0"

import { FrameCanvas } from "../components/frame/frame-canvas"
import { FrameDebugOverlay } from "../components/frame/frame-debug-overlay"
import { FrameDebugPanel } from "../components/frame/frame-debug-panel"
import { shellFrameLayout } from "../components/frame/frame-layout"
import { Dock } from "../components/dock"
import { Header } from "../components/header"
import { Sidebar } from "../components/sidebar"
import { DashboardScreen } from "../screens/dashboard"
import { DevScreen } from "../screens/dev"
import { GamingScreen } from "../screens/gaming"
import { SectionId } from "../store/navigation"

export function GlassShell() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  const stack = (
    <stack
      hexpand
      vexpand
      transitionType={Gtk.StackTransitionType.CROSSFADE}
      class="shell-content"
    >
      <box $type="named" name={SectionId.Dashboard}>
        <DashboardScreen />
      </box>
      <box $type="named" name={SectionId.Gaming}>
        <GamingScreen />
      </box>
      <box $type="named" name={SectionId.Dev}>
        <DevScreen />
      </box>
    </stack>
  ) as Gtk.Stack

  return (
    <window
      name="glass-shell"
      visible
      anchor={TOP | BOTTOM | LEFT | RIGHT}
      exclusivity={Astal.Exclusivity.IGNORE}
      layer={Astal.Layer.TOP}
      class="shell-window"
    >
      <overlay class="shell-root">
        <FrameCanvas />
        <box $type="overlay" hexpand vexpand class="shell-overlay-layer">
          <box
            orientation={Gtk.Orientation.VERTICAL}
            hexpand
            vexpand
            class="shell-stage"
            marginTop={shellFrameLayout.outerMargin + shellFrameLayout.frameTop + shellFrameLayout.contentInsetTop}
            marginBottom={shellFrameLayout.outerMargin + shellFrameLayout.frameBottom + shellFrameLayout.contentInsetBottom}
            marginStart={shellFrameLayout.outerMargin + shellFrameLayout.frameLeft + shellFrameLayout.contentInsetLeft}
            marginEnd={shellFrameLayout.outerMargin + shellFrameLayout.frameRight + shellFrameLayout.contentInsetRight}
          >
            {stack}
          </box>
        </box>
        <box
          $type="overlay"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.START}
          class="shell-floating shell-floating--top"
          marginTop={shellFrameLayout.topWidgetMarginTop}
        >
          <Header />
        </box>
        <box
          $type="overlay"
          halign={Gtk.Align.START}
          valign={Gtk.Align.CENTER}
          class="shell-floating shell-floating--left"
          marginStart={shellFrameLayout.leftWidgetMarginStart}
        >
          <Sidebar onNavigate={(section) => stack.set_visible_child_name(section)} />
        </box>
        <box
          $type="overlay"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.END}
          class="shell-floating shell-floating--bottom"
          marginBottom={shellFrameLayout.bottomWidgetMarginBottom}
        >
          <Dock />
        </box>
        <box $type="overlay" hexpand vexpand class="shell-debug-layer">
          <FrameDebugOverlay />
        </box>
        <box
          $type="overlay"
          halign={Gtk.Align.CENTER}
          valign={Gtk.Align.CENTER}
          class="shell-floating shell-floating--debug"
          canTarget={false}
        >
          <FrameDebugPanel />
        </box>
      </overlay>
    </window>
  )
}
