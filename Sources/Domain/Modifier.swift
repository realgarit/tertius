import Foundation

/// A keyboard modifier usable as the drag trigger.
///
/// `fn` is the globe/Fn key — selectable but flaky as a held modifier because
/// the system grabs it (emoji / input switch / dictation), so the UI carries a
/// caveat and the default is ``option``.
public enum Modifier: String, Sendable, CaseIterable, Codable, Equatable {
    case option
    case control
    case command
    case fn
}
