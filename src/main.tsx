#!/usr/bin/env -S ags run

import app from "ags/gtk4/app"
import theme from "./styles/main.scss"
import { GlassShell } from "./app/shell"

app.start({
  css: theme,
  main() {
    return <GlassShell />
  },
})
