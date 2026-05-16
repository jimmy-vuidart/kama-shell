pkgname=kama-shell
pkgver=0.1.0
pkgrel=1
pkgdesc="Quickshell session running on niri"
arch=('any')
url=""
license=('custom')
depends=(
    'niri'
    'quickshell-git'
    'xwayland-satellite'
)
optdepends=(
    'mako: notification daemon'
    'polkit-gnome: authentication agent'
    'xdg-desktop-portal-gnome: portals for Flatpak / screencast'
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

    install -m 755 "$repo_dir/sessions/start-kama-shell-niri-session" \
        "$bindir/start-kama-shell-niri-session"

    sed "0,/__KAMA_SHELL_APP_DIR__/s||/usr/share/$pkgname|" \
        "$repo_dir/sessions/kama-shell-niri-session" > "$bindir/kama-shell-niri-session"
    chmod 755 "$bindir/kama-shell-niri-session"

    sed "s|@PREFIX@|/usr|g" \
        "$repo_dir/sessions/kama-shell-niri.desktop" > "$sessiondir/kama-shell-niri.desktop"

    install -m 644 "$repo_dir/sessions/session.conf.example" \
        "$docdir/session.conf.example"
    install -m 644 "$repo_dir/config/kama.conf.example" \
        "$docdir/kama.conf.example"
    install -m 644 "$repo_dir/config/niri/config.kdl.example" \
        "$docdir/niri-config.kdl.example"
    install -m 644 "$repo_dir/config/niri/binds.kdl" \
        "$docdir/niri-binds.kdl"
}
