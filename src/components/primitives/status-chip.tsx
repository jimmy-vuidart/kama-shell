type StatusChipProps = {
  label: string
  tone?: "blue" | "violet" | "pink"
}

export function StatusChip(props: StatusChipProps) {
  const tone = props.tone ?? "blue"

  return <label class={`status-chip status-chip--${tone}`} label={props.label} />
}
