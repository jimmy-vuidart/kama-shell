pkgname=kama-shell
pkgver=0.1.0
pkgrel=1
pkgdesc="Minimal Quickshell session running on Niri Wayland"
arch=('any')
url=""
license=('custom')
depends=(
    'niri>=25.11'
    'quickshell-git'
)
optdepends=(
    'labwc: optional stacking compositor session via KAMA_COMPOSITOR=labwc'
    'grim: fullscreen screenshot helper under labwc'
    'wl-clipboard: clipboard target for the labwc screenshot helper'
    'xwayland-satellite: X11 application support under Niri'
    'xdg-desktop-portal-gnome: screencast portal support under Niri'
    'xdg-desktop-portal-gtk: fallback desktop portal support'
)
makedepends=()
source=()
sha256sums=()

package() {
    local appdir="$pkgdir/usr/share/$pkgname"
    local bindir="$pkgdir/usr/bin"
    local docdir="$pkgdir/usr/share/doc/$pkgname"
    local sessiondir="$pkgdir/usr/share/wayland-sessions"
    local repo_dir="$startdir"

    install -d "$appdir" "$bindir" "$docdir" "$sessiondir"

    install -m 755 "$repo_dir/run.sh" "$appdir/run.sh"
    install -m 644 "$repo_dir/qmldir" "$appdir/qmldir"
    cp -r "$repo_dir/src" "$appdir/src"
    cp -r "$repo_dir/scripts" "$appdir/scripts"

    install -m 755 "$repo_dir/sessions/start-kama-shell-session" \
        "$bindir/start-kama-shell-session"

    sed "0,/__KAMA_SHELL_APP_DIR__/s||/usr/share/$pkgname|" \
        "$repo_dir/sessions/kama-shell-session" > "$bindir/kama-shell-session"
    chmod 755 "$bindir/kama-shell-session"

    sed "s|@PREFIX@|/usr|g" \
        "$repo_dir/sessions/kama-shell.desktop" > "$sessiondir/kama-shell.desktop"

    install -m 644 "$repo_dir/sessions/session.conf.example" \
        "$docdir/session.conf.example"
    install -m 644 "$repo_dir/config/kama.conf.example" \
        "$docdir/kama.conf.example"
}
