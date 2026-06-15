# tertius

> A macOS menu-bar utility that gives the trackpad a true middle-mouse **drag**
> (orbit / pan for Blender and CAD), triggered by **⌥ + two-finger trackpad glide**.

On a mouse you orbit a 3D viewport by holding the middle button and moving the
mouse. The MacBook trackpad has no native equivalent, so 3D navigation is
crippled. `tertius` reproduces the mouse feel:

| Mouse | Trackpad (with tertius) |
| --- | --- |
| Scroll wheel → zoom | Two-finger scroll → zoom *(native, untouched)* |
| Hold middle button + move → orbit/pan | **⌥ + two-finger glide → middle-drag** |

The name is Latin for "third" — the third mouse button.

> **Status:** under active development. Milestones tracked in
> [`docs/superpowers/specs/2026-06-15-tertius-v1-design.md`](docs/superpowers/specs/2026-06-15-tertius-v1-design.md).

---

## Install (planned)

```sh
# one-time: disable Gatekeeper quarantine for brew casks (self-signed, not notarized)
echo 'export HOMEBREW_CASK_OPTS="--no-quarantine"' >> ~/.zshrc && source ~/.zshrc

brew install --cask realgarit/tap/tertius
```

On first launch, grant **Accessibility** (System Settings → Privacy & Security →
Accessibility). That's the only permission needed; it persists across
`brew upgrade` because the app is signed with a stable self-signed identity.

## Build from source

```sh
swift build      # build the package
swift test       # run the test suite
```

Requires Xcode 26 / macOS 26 SDK (deployment target is macOS 26.0).

## How it works

A single session-level `CGEventTap` watches trackpad `scrollWheel` events (which
carry a scroll *phase* and continuous deltas) and `flagsChanged` events (to track
the ⌥ modifier). While ⌥ is held and a two-finger scroll is in progress, the
native scroll is swallowed and translated into synthetic middle-button
down/drag/up events. Release ⌥ or lift your fingers and the drag ends; momentum
events are ignored so it ends crisply. When ⌥ is not held, scrolling is never
touched — native zoom passes through.

The codebase follows Clean Architecture: a pure, framework-free **Domain**
(decision logic), an **Application** layer of use cases + ports, **Infrastructure**
adapters for every OS mechanism, and an **App** composition root (SwiftUI
`MenuBarExtra`).

## Credits

Built on ideas/code from MIT-licensed projects — see [NOTICE](NOTICE).

## License

MIT © 2026 Patrik Lleshaj — see [LICENSE](LICENSE).
