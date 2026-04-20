import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { ControlCenterWidget } from "../widgets/control-center"
import { GameLibraryWidget } from "../widgets/game-library"
import { ProjectListWidget } from "../widgets/project-list"
import { SystemSummaryWidget } from "../widgets/system-summary"

export function DashboardScreen() {
  return (
    <box class="screen" spacing={18}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand class="screen__column screen__column--wide" spacing={18}>
        <SystemSummaryWidget />
        <GameLibraryWidget compact />
      </box>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand class="screen__column" spacing={18}>
        <ControlCenterWidget />
        <ProjectListWidget />
        <Card className="info-card">
          <label class="info-card__title" xalign={0} label="Shell Core" />
          <label
            class="info-card__body"
            wrap
            xalign={0}
            label="Bootstrap AGS actif, navigation prête, widgets encore sur données mockées."
          />
        </Card>
      </box>
    </box>
  )
}
