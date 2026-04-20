import Gtk from "gi://Gtk?version=4.0"

import { GameLibraryWidget } from "../widgets/game-library"

export function GamingScreen() {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="screen screen--single">
      <GameLibraryWidget />
    </box>
  )
}
