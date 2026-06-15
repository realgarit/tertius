import Foundation

/// How the middle-drag is triggered.
///
/// - ``twoFingerDrag``: modifier + two-finger trackpad glide (scroll phase). v1 primary.
/// - ``clickDrag``: modifier + physical click-drag. Optional alternate (future).
public enum InputMode: String, Sendable, CaseIterable, Codable, Equatable {
    case twoFingerDrag
    case clickDrag
}
