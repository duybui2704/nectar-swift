import Foundation

/// Active event — API `get-active-event` (Explore banner + Home footer).
struct ActiveEvent: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let description: String
    let bannerURL: URL?
}
