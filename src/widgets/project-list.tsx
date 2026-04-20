import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"
import { projects } from "../services/mock-data"

type ProjectListWidgetProps = {
  detailed?: boolean
}

export function ProjectListWidget(props: ProjectListWidgetProps) {
  const items = props.detailed ? projects : projects.slice(0, 4)

  return (
    <Card className="panel-card" hexpand vexpand>
      <SectionTitle
        title="Dev Universe"
        subtitle="Projects & tools"
        trailing={props.detailed ? "Workspace" : "Preview"}
      />
      <box class="tool-row" spacing={12}>
        {["VSCODE", "TERMINAL", "VITE", "NODE", "GIT", "DOCKER"].map((tool) => (
          <label class="tool-pill" label={tool} />
        ))}
      </box>
      <box orientation={Gtk.Orientation.VERTICAL} class="project-list" spacing={12}>
        {items.map((project) => (
          <box class="project-row">
            <box orientation={Gtk.Orientation.VERTICAL} hexpand spacing={4}>
              <label class="project-row__name" xalign={0} label={project.name} />
              <label class="project-row__path" xalign={0} label={project.path} />
            </box>
            <label class="project-row__stack" label={project.stack} />
            <label class="project-row__activity" label={project.activity} />
          </box>
        ))}
      </box>
    </Card>
  )
}
