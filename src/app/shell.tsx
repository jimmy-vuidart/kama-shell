import { Astal } from "ags/gtk4"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib?version=2.0"
import Cairo from "gi://cairo?version=1.0"

import { FrameCanvas } from "../components/frame/frame-canvas"
import { FrameDebugOverlay } from "../components/frame/frame-debug-overlay"
import { FrameDebugPanel } from "../components/frame/frame-debug-panel"
import { frameSize, innerPolygon } from "../components/frame/frame-debug"
import { shellFrameLayout } from "../components/frame/frame-layout"
import type { Point } from "../components/frame/frame-path"
import { Dock } from "../components/dock"
import { Header } from "../components/header"
import { Sidebar } from "../components/sidebar"
import { DashboardScreen } from "../screens/dashboard"
import { DevScreen } from "../screens/dev"
import { GamingScreen } from "../screens/gaming"
import { SectionId } from "../store/navigation"

const DEBUG_HANDLE_RADIUS = 26
const DEBUG_SEGMENT_THICKNESS = 20
const SHELL_INPUT_PADDING = 24
const SIDEBAR_INPUT_WIDTH = 156
const SIDEBAR_INPUT_HEIGHT = 460

function buildDebugHandleRegion(points: Point[]) {
  const region = new Cairo.Region()

  points.forEach((point) => {
    region.unionRectangle(new Cairo.RectangleInt({
      x: Math.floor(point.x - DEBUG_HANDLE_RADIUS),
      y: Math.floor(point.y - DEBUG_HANDLE_RADIUS),
      width: DEBUG_HANDLE_RADIUS * 2,
      height: DEBUG_HANDLE_RADIUS * 2,
    }))
  })

  for (let index = 0; index < points.length; index += 1) {
    const start = points[index]
    const end = points[(index + 1) % points.length]
    const minX = Math.min(start.x, end.x) - DEBUG_SEGMENT_THICKNESS
    const minY = Math.min(start.y, end.y) - DEBUG_SEGMENT_THICKNESS
    const maxX = Math.max(start.x, end.x) + DEBUG_SEGMENT_THICKNESS
    const maxY = Math.max(start.y, end.y) + DEBUG_SEGMENT_THICKNESS

    region.unionRectangle(new Cairo.RectangleInt({
      x: Math.floor(minX),
      y: Math.floor(minY),
      width: Math.ceil(maxX - minX),
      height: Math.ceil(maxY - minY),
    }))
  }

  return region
}

function buildShellUiRegion(width: number, height: number) {
  const region = new Cairo.Region()

  const headerWidth = shellFrameLayout.topTabWidth + SHELL_INPUT_PADDING * 2
  const headerHeight = shellFrameLayout.topTabHeight + SHELL_INPUT_PADDING * 2
  const headerX = (width - headerWidth) / 2
  const headerY = 0

  const sidebarX = 0
  const sidebarY = Math.max(0, (height - SIDEBAR_INPUT_HEIGHT) / 2)

  const dockWidth = shellFrameLayout.bottomDockWidth + SHELL_INPUT_PADDING * 2
  const dockHeight = shellFrameLayout.bottomDockHeight + SHELL_INPUT_PADDING * 2
  const dockX = (width - dockWidth) / 2
  const dockY = Math.max(0, height - dockHeight)

  region.unionRectangle(new Cairo.RectangleInt({
    x: Math.floor(headerX),
    y: Math.floor(headerY),
    width: Math.ceil(headerWidth),
    height: Math.ceil(headerHeight),
  }))

  region.unionRectangle(new Cairo.RectangleInt({
    x: Math.floor(sidebarX),
    y: Math.floor(sidebarY),
    width: SIDEBAR_INPUT_WIDTH,
    height: SIDEBAR_INPUT_HEIGHT,
  }))

  region.unionRectangle(new Cairo.RectangleInt({
    x: Math.floor(dockX),
    y: Math.floor(dockY),
    width: Math.ceil(dockWidth),
    height: Math.ceil(dockHeight),
  }))

  return region
}

function updateWindowInputRegion(window: Gtk.Window) {
  const { width, height } = frameSize.peek()
  const points = innerPolygon.peek().points

  if (!width || !height) {
    window.get_surface()?.set_input_region(new Cairo.Region())
    return
  }

  const region = buildShellUiRegion(width, height)
  if (points.length > 0) {
    region.union(buildDebugHandleRegion(points))
  }

  window.get_surface()?.set_input_region(region)
}

function bindWindowInputRegion(window: Gtk.Window) {
  const applyInputRegion = () => {
    updateWindowInputRegion(window)
    return GLib.SOURCE_REMOVE
  }

  updateWindowInputRegion(window)
  GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
    updateWindowInputRegion(window)
    return GLib.SOURCE_REMOVE
  })

  const unsubscribeSize = frameSize.subscribe(applyInputRegion)
  const unsubscribePolygon = innerPolygon.subscribe(applyInputRegion)
  window.connect("destroy", () => {
    unsubscribeSize()
    unsubscribePolygon()
  })
}

export function GlassShell() {
  const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor

  const stack = (
    <stack
      hexpand
      vexpand
      transitionType={Gtk.StackTransitionType.CROSSFADE}
      class="shell-content"
    >
      <box $type="named" name={SectionId.Dashboard}>
        <DashboardScreen />
      </box>
      <box $type="named" name={SectionId.Gaming}>
        <GamingScreen />
      </box>
      <box $type="named" name={SectionId.Dev}>
        <DevScreen />
      </box>
    </stack>
  ) as Gtk.Stack

  return (
    <>
      <window
        name="glass-shell"
        namespace="glass-shell"
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.NONE}
        layer={Astal.Layer.TOP}
        class="shell-window"
        visible
        $={(self) => {
          bindWindowInputRegion(self)
          self.connect("notify::mapped", () => updateWindowInputRegion(self))
        }}
      >
        <overlay class="shell-root" canTarget>
          <box
            $type="overlay"
            hexpand
            vexpand
            canTarget={false}
            class="shell-frame-layer"
          >
            <FrameCanvas />
          </box>
          <box hexpand vexpand class="shell-base-layer" canTarget>
            <box
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.START}
              class="shell-floating shell-floating--top"
              marginTop={shellFrameLayout.topWidgetMarginTop}
              canTarget
            >
              <Header />
            </box>
            <box
              halign={Gtk.Align.START}
              valign={Gtk.Align.CENTER}
              class="shell-floating shell-floating--left"
              marginStart={shellFrameLayout.leftWidgetMarginStart}
              canTarget
            >
              <Sidebar onNavigate={(section) => stack.set_visible_child_name(section)} />
            </box>
            <box
              halign={Gtk.Align.CENTER}
              valign={Gtk.Align.END}
              class="shell-floating shell-floating--bottom"
              marginBottom={shellFrameLayout.bottomWidgetMarginBottom}
              canTarget
            >
              <Dock />
            </box>
          </box>
          <box $type="overlay" hexpand vexpand class="shell-debug-layer" canTarget>
            <FrameDebugOverlay />
          </box>
          <box
            $type="overlay"
            halign={Gtk.Align.CENTER}
            valign={Gtk.Align.CENTER}
            class="shell-floating shell-floating--debug"
            canTarget={false}
          >
            <FrameDebugPanel />
          </box>
        </overlay>
      </window>
      <window
        name="glass-shell-stage"
        namespace="glass-shell-stage"
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.NONE}
        layer={Astal.Layer.BOTTOM}
        class="shell-window shell-window--stage"
        visible
      >
        <overlay class="shell-root" canTarget={false}>
          <box $type="overlay" hexpand vexpand class="shell-overlay-layer" canTarget={false}>
            <box
              orientation={Gtk.Orientation.VERTICAL}
              hexpand
              vexpand
              class="shell-stage"
              marginTop={shellFrameLayout.outerMargin + shellFrameLayout.frameTop + shellFrameLayout.contentInsetTop}
              marginBottom={shellFrameLayout.outerMargin + shellFrameLayout.frameBottom + shellFrameLayout.contentInsetBottom}
              marginStart={shellFrameLayout.outerMargin + shellFrameLayout.frameLeft + shellFrameLayout.contentInsetLeft}
              marginEnd={shellFrameLayout.outerMargin + shellFrameLayout.frameRight + shellFrameLayout.contentInsetRight}
              canTarget={false}
            >
              {stack}
            </box>
          </box>
        </overlay>
      </window>
    </>
  )
}
