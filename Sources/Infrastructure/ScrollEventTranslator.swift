import CoreGraphics
import Foundation
import Domain

/// Translates a raw `CGEvent` into a normalized ``GestureSample``. Pure mapping
/// with no side effects, so it is unit-tested against synthetic events. The
/// event tap is a thin shell around this.
public enum ScrollEventTranslator {

    public static func sample(from event: CGEvent, type: CGEventType) -> GestureSample? {
        let modifiers = modifiers(from: event.flags)
        let timestamp = TimeInterval(event.timestamp) / 1_000_000_000 // ns since boot → seconds

        switch type {
        case .scrollWheel:
            let momentumRaw = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
            let isMomentum = momentumRaw != 0
            let scrollPhaseRaw = event.getIntegerValueField(.scrollWheelEventScrollPhase)
            let phase: ScrollPhase = isMomentum ? .none : mapScrollPhase(scrollPhaseRaw)
            let continuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0

            // Axis1 = vertical (Y), Axis2 = horizontal (X). Fixed-point read as
            // Double gives sub-pixel precision.
            let dy = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
            let dx = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)

            return GestureSample(
                kind: .scroll, phase: phase, isMomentum: isMomentum, isContinuous: continuous,
                deltaX: dx, deltaY: dy, activeModifiers: modifiers, timestamp: timestamp
            )

        case .flagsChanged:
            return GestureSample(
                kind: .modifierChange, phase: .none, isMomentum: false, isContinuous: false,
                deltaX: 0, deltaY: 0, activeModifiers: modifiers, timestamp: timestamp
            )

        default:
            return nil
        }
    }

    /// CGScrollPhase raw values are bit-flag-like (1/2/4/8/128), not 0/1/2.
    private static func mapScrollPhase(_ raw: Int64) -> ScrollPhase {
        switch raw {
        case 1: return .began      // kCGScrollPhaseBegan
        case 2: return .changed    // kCGScrollPhaseChanged
        case 4: return .ended      // kCGScrollPhaseEnded
        case 8: return .ended      // kCGScrollPhaseCancelled → release the drag
        default: return .none      // mayBegin (128) or 0 (legacy wheel)
        }
    }

    static func modifiers(from flags: CGEventFlags) -> Set<Modifier> {
        var result: Set<Modifier> = []
        if flags.contains(.maskAlternate) { result.insert(.option) }
        if flags.contains(.maskControl) { result.insert(.control) }
        if flags.contains(.maskCommand) { result.insert(.command) }
        if flags.contains(.maskSecondaryFn) { result.insert(.fn) }
        return result
    }
}
