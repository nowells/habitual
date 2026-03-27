import Foundation

/// Provides a stable, per-device identifier used as part of the CRDT identity
/// for CDCompletion records. Each device generates a UUID on first use and
/// persists it in the shared app-group UserDefaults so that all targets
/// (iOS app, widgets, watchOS) on the same device share the same ID.
///
/// When a completion is created, it is stamped with `(deviceID, createdAt)`.
/// This pair uniquely identifies the user action that produced the record.
/// During CloudKit sync, if the same CKRecord is re-imported as a new local
/// object with a different CoreData UUID, we can still detect the duplicate
/// by matching on `(deviceID, createdAt)`.
enum DeviceIdentifier {
    private static let key = "com.habitual.deviceID"
    private static let appGroupID = "group.com.habitual-helper.app"

    /// The stable device identifier. Generated once and cached.
    static let current: String = {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard

        if let existing = defaults.string(forKey: key), !existing.isEmpty {
            return existing
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: key)
        return newID
    }()
}
