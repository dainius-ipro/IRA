import Foundation
import SwiftData

/// SwiftData persistent model for Session
@Model
final class StoredSession {
@Attribute(.unique) var id: UUID
var date: Date
var vehicle: String?
var racer: String?
var track: String?

```
@Relationship(deleteRule: .cascade) var laps: [StoredLap]

init(id: UUID, date: Date, vehicle: String?, racer: String?, track: String?, laps: [StoredLap]) {
    self.id = id
    self.date = date
    self.vehicle = vehicle
    self.racer = racer
    self.track = track
    self.laps = laps
}

convenience init(from session: Session) {
    self.init(
        id: session.id,
        date: session.date,
        vehicle: session.vehicle,
        racer: session.racer,
        track: session.track,
        laps: session.laps.map { StoredLap(from: $0) }
    )
}

func toSession() -> Session {
    Session(
        id: id,
        date: date,
        vehicle: vehicle,
        racer: racer,
        track: track,
        laps: laps.map { $0.toLap() }
    )
}
```

}