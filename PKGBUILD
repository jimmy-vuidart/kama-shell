pkgname=kama-shell
pkgver=0.1.0
pkgrel=1
pkgdesc="Minimal Quickshell session running on KWin Wayland"
arch=('any')
url=""
license=('custom')
depends=(
    'kwin'
    'quickshell-git'
    'plasma-workspace'
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
    cp -r "$repo_dir/kwin" "$appdir/kwin"

    install -m 755 "$repo_dir/sessions/start-kama-shell-session" \
        "$bindir/start-kama-shell-session"

    sed "0,/__KAMA_SHELL_APP_DIR__/s||/usr/share/$pkgname|" \
        "$repo_dir/sessions/kama-shell-session" > "$bindir/kama-shell-session"
    chmod 755 "$bindir/kama-shell-session"

    sed "s|@PREFIX@|/usr|g" \
        "$repo_dir/sessions/kama-shell.desktop" > "$sessiondir/kama-shell.desktop"

    install -m 644 "$repo_dir/sessions/session.conf.example" \
        "$docdir/session.conf.example"
}
