import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"
import { systemMetrics } from "../services/mock-data"

export function SystemSummaryWidget() {
  return (
    <Card className="metrics-card">
      <SectionTitle
        title="System Overview"
        subtitle="Widgets branchés sur mocks réalistes en attendant les adaptateurs Linux."
        trailing="Dashboard"
      />
      <box class="metrics-grid" spacing={12}>
        {systemMetrics.map((metric) => (
          <box orientation={Gtk.Orientation.VERTICAL} class="metric-pill" spacing={8}>
            <label class="metric-pill__label" label={metric.label} />
            <label class="metric-pill__value" label={metric.value} />
            <label class="metric-pill__meta" label={metric.meta} />
          </box>
        ))}
      </box>
    </Card>
  )
}
