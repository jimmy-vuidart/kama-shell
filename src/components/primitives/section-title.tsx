import Gtk from "gi://Gtk?version=4.0"

type SectionTitleProps = {
  title: string
  subtitle?: string
  trailing?: string
}

export function SectionTitle(props: SectionTitleProps) {
  return (
    <box class="section-title" spacing={16}>
      <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={6}>
        <label class="section-title__heading" xalign={0} label={props.title} />
        {props.subtitle ? (
          <label class="section-title__subtitle" xalign={0} label={props.subtitle} />
        ) : null}
      </box>
      {props.trailing ? (
        <label class="section-title__trailing" label={props.trailing} />
      ) : null}
    </box>
  )
}
