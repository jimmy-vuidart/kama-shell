import Gtk from "gi://Gtk?version=4.0"

import { ProjectListWidget } from "../widgets/project-list"

export function DevScreen() {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="screen screen--single">
      <ProjectListWidget detailed />
    </box>
  )
}
