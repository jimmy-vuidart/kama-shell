import Gtk from "gi://Gtk?version=4.0"

import { SectionId, sections } from "../store/navigation"

type SidebarProps = {
  onNavigate: (section: SectionId) => void
}

export function Sidebar(props: SidebarProps) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="sidebar" valign={Gtk.Align.CENTER}>
      <box orientation={Gtk.Orientation.VERTICAL} class="sidebar__rail" spacing={12}>
        <label class="sidebar__brand" label="UNIVERSE" />
        <label class="sidebar__brand" label="DOCK" />
        {sections.map((section, index) => (
          <button
            class={`sidebar__item ${index === 0 ? "sidebar__item--active" : ""}`}
            onClicked={() => props.onNavigate(section.id)}
          >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={8}>
              <label class="sidebar__item-icon" label={section.icon} />
              <label class="sidebar__item-label" label={section.label} />
            </box>
          </button>
        ))}
        <box hexpand vexpand />
        <button class="sidebar__settings">
          <label label="SYS" />
        </button>
      </box>
    </box>
  )
}
