import { Astal } from "ags/gtk4"
import Gtk from "gi://Gtk?version=4.0"

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
      <box orientation={Gtk.Orientation.VERTICAL} class="shell-root" spacing={18}>
        <Header />
        <box hexpand vexpand class="shell-body" spacing={18}>
          <Sidebar onNavigate={(section) => stack.set_visible_child_name(section)} />
          {stack}
        </box>
        <Dock />
      </box>
    </window>
  )
}
