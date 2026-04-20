import Gtk from "gi://Gtk?version=4.0"

import { Card } from "../components/primitives/card"
import { SectionTitle } from "../components/primitives/section-title"
import {
  batteryMetric,
  cpuMetric,
  memoryMetric,
  networkMetric,
} from "../services/system-state"

function MetricPill(props: {
  label: string
  value: string | ReturnType<typeof cpuMetric>
  meta: string | ReturnType<typeof cpuMetric>
}) {
  return (
    <box orientation={Gtk.Orientation.VERTICAL} class="metric-pill" spacing={8}>
      <label class="metric-pill__label" label={props.label} />
      <label class="metric-pill__value" label={props.value} />
      <label class="metric-pill__meta" label={props.meta} />
    </box>
  )
}

export function SystemSummaryWidget() {
  return (
    <Card className="metrics-card">
      <SectionTitle
        title="System Overview"
        subtitle="CPU, RAM, batterie et réseau issus du système avec fallbacks."
        trailing={networkMetric((metric) => metric.status.toUpperCase())}
      />
      <box class="metrics-grid" spacing={12}>
        <MetricPill
          label="CPU"
          value={cpuMetric((metric) => metric.value)}
          meta={cpuMetric((metric) => metric.meta)}
        />
        <MetricPill
          label="RAM"
          value={memoryMetric((metric) => metric.value)}
          meta={memoryMetric((metric) => metric.meta)}
        />
        <MetricPill
          label="Battery"
          value={batteryMetric((metric) => metric.value)}
          meta={batteryMetric((metric) => metric.meta)}
        />
        <MetricPill
          label="Network"
          value={networkMetric((metric) => metric.value)}
          meta={networkMetric((metric) => metric.meta)}
        />
      </box>
    </Card>
  )
}
