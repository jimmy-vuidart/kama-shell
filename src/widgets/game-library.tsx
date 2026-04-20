import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"
import { gameLaunchers, gameLibrary } from "../services/mock-data"

type GameLibraryWidgetProps = {
  compact?: boolean
}

export function GameLibraryWidget(props: GameLibraryWidgetProps) {
  const games = props.compact ? gameLibrary.slice(0, 4) : gameLibrary

  return (
    <Card className="panel-card" hexpand vexpand>
      <SectionTitle
        title="Gaming Universe"
        subtitle="Launchers & library"
        trailing={props.compact ? "Preview" : "Full"}
      />
      <box class="launcher-strip" spacing={12}>
        {gameLaunchers.map((launcher) => (
          <box orientation={Gtk.Orientation.VERTICAL} class="launcher-chip" spacing={6}>
            <label class="launcher-chip__name" label={launcher.name} />
            <label class="launcher-chip__meta" label={launcher.status} />
          </box>
        ))}
      </box>
      <box class="game-grid" spacing={14}>
        {games.map((game) => (
          <box orientation={Gtk.Orientation.VERTICAL} class="game-tile" spacing={6}>
            <box class={`game-tile__cover game-tile__cover--${game.accent}`} />
            <label class="game-tile__title" label={game.title} />
            <label class="game-tile__meta" label={game.source} />
          </box>
        ))}
      </box>
    </Card>
  )
}
