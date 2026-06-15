import Foundation

/// Pure, stateless predicate: is the user currently requesting middle-drag mode
/// for this sample? This is the engagement decision, independent of phase or
/// drag state (which the ``DragStateMachine`` owns).
public enum TriggerPolicy {
    /// True when middle-drag is enabled, the active mode is two-finger drag, and
    /// the configured modifier is currently held.
    public static func isEngaged(_ sample: GestureSample, settings: AppSettings) -> Bool {
        guard settings.enabled, settings.inputMode == .twoFingerDrag else { return false }
        return sample.activeModifiers.contains(settings.modifier)
    }
}
