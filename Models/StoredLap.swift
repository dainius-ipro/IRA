import Foundation
import SwiftData

/// SwiftData persistent model for Lap
@Model
final class StoredLap {
    @Attribute(.unique) var id: UUID
    var lapTime: TimeInterval
    var sectorTimes: [TimeInterval]?
    var isValid: Bool
    var session: StoredSession?    // reverse relationship

    init(id: UUID = UUID(),
         lapTime: TimeInterval,
         sectorTimes: [TimeInterval]? = nil,
         isValid: Bool = true,
         session: StoredSession? = nil) {
        self.id = id
        self.lapTime = lapTime
        self.sectorTimes = sectorTimes
        self.isValid = isValid
        self.session = session
    }

    /// konvertavimas į paprastą Lap modelį (jei toks egzistuoja)
    func toLap() -> Lap {
        Lap(id: id, lapTime: lapTime, sectorTimes: sectorTimes ?? [])
    }

    /// convenience init iš Lap
    convenience init(from lap: Lap) {
        self.init(id: lap.id, lapTime: lap.lapTime, sectorTimes: lap.sectorTimes)
    }
}