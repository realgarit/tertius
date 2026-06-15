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

---

## Install

```sh
# one-time: brew casks apply Gatekeeper quarantine by default; tertius is signed
# with a self-signed identity (not notarized), so disable quarantine for casks:
echo 'export HOMEBREW_CASK_OPTS="--no-quarantine"' >> ~/.zshrc && source ~/.zshrc

brew install --cask realgarit/tap/tertius
```

Update with `brew upgrade --cask tertius`. The app also checks GitHub Releases on
launch and via **Check for Updates…**, and tells you when a newer version exists
(it never auto-installs).

> Requires macOS 26 (Tahoe) or newer, Apple Silicon or Intel.

## First run

1. Launch Tertius (`open -a Tertius`). It lives in the **menu bar** (a mouse
   icon) — there's no Dock icon.
2. On first launch it asks for **Accessibility** permission, which it needs to
   read trackpad gestures and post the synthetic middle-button. Enable
   **Tertius** under **System Settings → Privacy & Security → Accessibility**
   (use the menu's **Grant Accessibility…** if you dismissed the prompt).
3. The gesture starts working within a couple of seconds of granting — no
   relaunch needed.

The Accessibility grant **persists across `brew upgrade`**: the app is signed
with a stable self-signed identity, so macOS keeps recognising it as the same app.

## Usage

In Blender (and CAD apps that read middle-drag motion):

- **⌥ + glide two fingers** on the trackpad → orbits/pans the viewport, like
  holding the middle mouse button and moving the mouse.
- **Plain two-finger scroll** still zooms — native behaviour is untouched.
- A physical mouse wheel is never intercepted, so **⌥ + wheel** keeps working in
  other apps.

Tip for Blender: enable *Preferences → Input → Emulate 3-Button Mouse*, which
also maps ⌥ to the middle button — tertius aligns with that convention.

## Settings

Open from the menu (**Settings…**):

| Setting | What it does |
| --- | --- |
| **Enable** | Master on/off. |
| **Modifier** | ⌥ Option (default), ⌃ Control, ⌘ Command, or Fn. *(Fn is grabbed by the system for emoji/dictation and is unreliable — a caveat is shown.)* |
| **Mode** | Two-finger drag (default) or click-drag. |
| **Sensitivity** | Orbit speed, 0.1×–30× (default 5×). Raise it if orbit feels slow. |
| **Invert X / Invert Y** | Flip either axis if orbit goes the wrong way. |
| **Launch at login** | Register as a login item (`SMAppService`). |

Settings persist across relaunches.

## How it works

A single session-level `CGEventTap` watches trackpad `scrollWheel` events (which
carry a scroll *phase* and continuous deltas) and `flagsChanged` events (to track
the modifier). While the modifier is held and a two-finger scroll is in progress,
the native scroll is swallowed and translated into synthetic middle-button
down/drag/up events. Release the modifier or lift your fingers and the drag ends;
inertial momentum events are ignored so it ends crisply.

The codebase follows Clean Architecture, with source dependencies pointing only
inward:

- **Domain** — pure decision logic (`TriggerPolicy`, `DragStateMachine`, value
  types). Imports only `Foundation`; exhaustively unit-tested.
- **Application** — use cases + ports (protocols).
- **Infrastructure** — adapters for every OS mechanism (the event tap, CGEvent
  posting, `UserDefaults`, Accessibility, `SMAppService`, GitHub Releases).
- **App** — the SwiftUI `MenuBarExtra` composition root.

## Build from source

```sh
swift build        # build the package
swift test         # run the full suite

# build a signed .app bundle (needs a code-signing identity)
SIGN_IDENTITY="Tertius Self-Signed" scripts/package-app.sh
```

Requires Xcode 26 / the macOS 26 SDK.

## Troubleshooting

- **Downloaded the zip directly (not via brew)?** A non-brew download is
  quarantined. Right-click the app → **Open** once, or run
  `xattr -dr com.apple.quarantine /Applications/Tertius.app`.
- **Orbit feels slow?** Raise **Sensitivity** in Settings (up to 30×).
- **Orbit goes the wrong way?** Toggle **Invert X** / **Invert Y**.
- **Gesture stopped working?** macOS can disable an event tap under load; tertius
  re-arms automatically, but toggling **Enable** off/on, or relaunching, also
  resets it. Confirm **Tertius** is still ticked under Accessibility.

## Credits

Built on ideas/code from MIT-licensed projects — see [NOTICE](NOTICE).

## License

MIT © 2026 Patrik Lleshaj — see [LICENSE](LICENSE).
