import CoreGraphics
import Foundation
import Domain
import Application

public enum InputSourceError: Error {
    case tapCreationFailed
}

/// The v1 primary input source: a session-level `CGEventTap` over `scrollWheel`
/// and `flagsChanged` events. A thin shell — all field decoding lives in the
/// unit-tested ``ScrollEventTranslator``, and all decisions in the Domain. This
/// adapter only owns the tap lifecycle and the swallow handoff.
///
/// Requires Accessibility + PostEvent access; `tapCreate` returns nil without it.
public final class ScrollGestureInputSource: InputSource {
    public var onSample: ((GestureSample) -> Bool)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public func start() throws {
        guard tap == nil else { return }

        let mask = CGEventMask(
            (1 << CGEventType.scrollWheel.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        )

        // Non-capturing C callback; instance state is recovered via userInfo.
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let source = Unmanaged<ScrollGestureInputSource>.fromOpaque(refcon).takeUnretainedValue()
            return source.handle(type: type, event: event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap, // active filter — required to swallow events
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw InputSourceError.tapCreationFailed
        }

        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        tap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The OS can disable the tap under load — re-arm and pass the event.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard let sample = ScrollEventTranslator.sample(from: event, type: type) else {
            return Unmanaged.passUnretained(event)
        }

        let swallow = onSample?(sample) ?? false
        return swallow ? nil : Unmanaged.passUnretained(event)
    }
}
