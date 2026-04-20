import Gtk from "gi://Gtk?version=4.0"

type CardProps = {
  className?: string
  hexpand?: boolean
  vexpand?: boolean
  vertical?: boolean
  children?: JSX.Element | JSX.Element[]
}

export function Card(props: CardProps) {
  const className = props.className ? `card ${props.className}` : "card"

  return (
    <box
      orientation={(props.vertical ?? true) ? Gtk.Orientation.VERTICAL : Gtk.Orientation.HORIZONTAL}
      hexpand={props.hexpand}
      vexpand={props.vexpand}
      class={className}
      spacing={16}
    >
      {props.children}
    </box>
  )
}
