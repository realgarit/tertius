# macOS 26 API reference (verified)

Distilled from a research pass that was adversarially fact-checked against the
macOS 26.5 SDK headers and the Swift 6.3 compiler. Only the load-bearing,
**corrected** facts are kept here — this is what the Infrastructure adapters
implement against.

## CGEventTap (ScrollGestureInputSource)

- `CGEvent.tapCreate(tap:place:options:eventsOfInterest:callback:userInfo:) -> CFMachPort?`
  returns `nil` when the process lacks permission — that is the normal "not yet
  granted" signal; handle it, don't force-unwrap.
- Tap location: **`.cgSessionEventTap`**. Placement: **`.headInsertEventTap`**
  (the other case is `.tailAppendEventTap` — there is NO `.tailInsertEventTap`).
- Options: **`.defaultTap`** is required to swallow events (a `.listenOnly` tap
  cannot filter). To pass an event, return `Unmanaged.passUnretained(event)`; to
  **swallow**, return `nil`.
- Callback closure type is `(CGEventTapProxy, CGEventType, CGEvent, UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>?`
  (non-optional `CGEvent`; the Swift return is `Unmanaged<CGEvent>?`, not `CGEvent?`).
  It must be non-capturing — pass `self` via `userInfo`:
  `Unmanaged.passUnretained(self).toOpaque()` → recover with
  `Unmanaged<T>.fromOpaque(refcon!).takeUnretainedValue()`.
- Event mask: `CGEventMask((1 << CGEventType.scrollWheel.rawValue) | (1 << CGEventType.flagsChanged.rawValue))`
  (`scrollWheel` = 22, `flagsChanged` = 12; `rawValue` is `UInt32`, so wrap in `CGEventMask(...)`).
- Run loop: `CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)` →
  `CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)`. A tap is
  **enabled** when created (calling `CGEvent.tapEnable(tap:enable:true)` is still
  fine/idempotent), but needs a running run loop to deliver events.
- The OS can disable the tap and deliver `.tapDisabledByTimeout` /
  `.tapDisabledByUserInput` through the same callback — re-arm with
  `CGEvent.tapEnable(tap:enable:true)` and pass the event.

## Scroll event fields (ScrollEventTranslator)

Read with `event.getIntegerValueField(_:)` (→ `Int64`) / `getDoubleValueField(_:)` (→ `Double`).

- **Scroll phase** — `.scrollWheelEventScrollPhase` (field 99) → `CGScrollPhase`,
  which is **bit-flag-like, NOT 0/1/2**:
  `began = 1, changed = 2, ended = 4, cancelled = 8, mayBegin = 128`; `0` means
  no phase info (a legacy/line mouse wheel). Map `cancelled` → treat like `ended`;
  `mayBegin` → ignore.
- **Momentum phase** — `.scrollWheelEventMomentumPhase` (field 123) →
  `CGMomentumScrollPhase` (sequential): `none = 0, begin = 1, continuous = 2, end = 3`.
  (Swift case for value 2 is `.continuous`, not `.continue`.) `isMomentum` =
  momentum phase != 0.
- **Continuous** — `.scrollWheelEventIsContinuous` (field 88): non-zero = pixel
  scroll (trackpad / Magic Mouse); 0 = notched wheel. Only continuous scrolls
  trigger orbit.
- **Deltas** — prefer `.scrollWheelEventFixedPtDeltaAxis1/2` (93/94) read as
  `Double` for sub-pixel precision. **Axis1 = vertical (Y), Axis2 = horizontal (X).**
  (`PointDeltaAxis1/2` = 96/97 are integer-pixel; `DeltaAxis1/2` = 11/12 are coarse line steps.)

## Posting the middle button (MiddleButtonEventFactory / CGEventPointerActuator)

- Middle button is **`CGMouseButton.center` (rawValue 2)** — verified against
  `kCGMouseButtonCenter = 2`. (The brief's prose "button 3" was wrong.)
- Event types: `.otherMouseDown` (25), `.otherMouseDragged` (27), `.otherMouseUp` (26).
- Build: `CGEvent(mouseEventSource:nil, mouseType:.otherMouseDown, mouseCursorPosition:pt, mouseButton:.center)`
  then `event.setIntegerValueField(.mouseEventButtonNumber, value: 2)` and `event.post(tap: .cgSessionEventTap)`.
  (`mouseButton` is only honored for the `otherMouse*` types.)
- **Motion deltas (required for drag)** — set `.mouseEventDeltaX` (4) /
  `.mouseEventDeltaY` (5) on each `.otherMouseDragged`. These integer fields are
  what `[NSEvent deltaX/deltaY]` exposes and what apps read for *relative* motion
  (Godot orbit). Our gesture is a two-finger scroll, so the real cursor never
  travels and these default to **0** — the target then orbits by nothing even
  though the button is held. Setting `mouseCursorPosition` alone is not enough for
  relative-motion consumers. Accumulate sub-pixel scroll deltas in a `Double`
  running position and emit `round(pos) − round(prevPos)` per event so slow
  glides tick over instead of rounding away. (Warping the cursor with
  `CGWarpMouseCursorPosition` is optional and unnecessary once the deltas are set;
  it also incurs a ~250 ms post-warp delta-suppression window.)
- Current cursor: `CGEvent(source: nil)?.location` (CGPoint, global **top-left**
  display coordinates — same space as the synthetic events). `NSEvent.mouseLocation`
  is bottom-left, so prefer the CGEvent location to avoid a flip.

## Permissions (AXAccessibilityAuthorizer) — important correction

Three **distinct** TCC privileges, two of which both surface under the
**Accessibility** row in System Settings:

- **PostEvent** gates `CGEvent.post` (synthetic events). Check/request with
  `CGPreflightPostEventAccess()` / `CGRequestPostEventAccess()`. Distinct from
  Accessibility, and can disagree with `AXIsProcessTrusted()`.
- **ListenEvent** gates system-wide event-tap *listening* (shown as
  "Input Monitoring"): `CGPreflightListenEventAccess()` / `CGRequestListenEventAccess()`.
- **Accessibility** (`AXIsProcessTrusted()` / `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`)
  gates UI control; this is the user-facing grant whose persistence we care about.

Practical plan: an **active filtering** session tap (`.defaultTap`) plus posting
events needs Accessibility AND PostEvent — both appear under the Accessibility
row. Preflight all of them; prompt with `AXIsProcessTrustedWithOptions` and call
`CGRequestPostEventAccess()`. Deep link via `NSWorkspace.shared.open(URL(string:
"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)`
(works through NSWorkspace, not the `open` CLI). Posting events does NOT require a
sandboxed-off binary per se, but our active tap + Accessibility usage does — keep
**App Sandbox OFF**.

## SMAppService (launch at login, M3)

- `SMAppService.mainApp.register() throws` (sync only — no async/completion form),
  `unregister()` (sync throws, also `async throws`), `.status` →
  `SMAppService.Status` (Int-backed: `notRegistered=0, enabled=1, requiresApproval=2, notFound=3`).
  macOS 13+.

## MenuBarExtra / packaging (M3 / M4)

- `MenuBarExtra` content closures use `@ContentBuilder`. `Settings` scene is
  macOS 11+. No Dock icon via `LSUIElement` (Boolean `<true/>`) in Info.plist
  plus `NSApp.setActivationPolicy(.accessory)`.
- Universal build: `swift build -c release --arch arm64 --arch x86_64`;
  `--show-bin-path` returns a **directory**, append the product name.
- App icon: `actool --compile <Resources> --app-icon AppIcon --output-partial-info-plist p.plist Assets.xcassets`
  — the output directory must already exist; emits `Assets.car` (+ a compat `AppIcon.icns`).

## Self-signed signing (scripts/make-signing-cert.sh, M2/M4)

- System `openssl` is LibreSSL → **omit `-legacy`** on `openssl pkcs12 -export`.
- EKU must be `codeSigning`. Import: `security import cert.p12 -k <kc> -P <pw> -T /usr/bin/codesign`.
- Non-interactive signing: `security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k <kc-pw> <kc>`.
- Sign single-executable bundles **without `--deep`** (Apple discourages it; sign
  nested code inside-out — but we have none).
- A self-signed cert yields a stable DR:
  `designated => identifier "<bundle id>" and certificate leaf = H"<sha1>"`.
  Identical across rebuilds with the same cert + bundle id ⇒ the Accessibility
  grant persists. Verify with `codesign -d --requirements - <app>`.

## CI runner (M5)

- `macos-26` carries the macOS 26 SDK and an Xcode 26 by default (used; works).
  `macos-15` also has Xcode 26 SDKs now (select via `setup-xcode`), but
  `macos-26` is cleanest. `macos-latest` still defaults to Xcode 16.4 — do not
  rely on it for a 26.0 target.
