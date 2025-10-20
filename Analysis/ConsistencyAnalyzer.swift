import SwiftUI

/// Minimalus analizatoriaus stub'as, kad „ConsistencyView“ turėtų iš ko kviesti metodus
final class ConsistencyAnalyzer {

    // 0–100, kuo didesnis – tuo stabilesni laikai
    func calculateConsistencyScore(laps: [StoredLap]) -> Double {
        let times = laps.map { $0.lapTime }
        guard let avg = times.average, let std = times.std, avg > 0 else { return 0 }
        // paprastas skaičiavimas: kuo mažesnis std/avg, tuo didesnis score
        let consistency = max(0, 100 * (1 - min(std / avg, 1)))
        return consistency
    }

    func findOutliers(laps: [StoredLap]) -> [StoredLap] {
        let times = laps.map { $0.lapTime }
        guard let avg = times.average, let std = times.std else { return [] }
        let upper = avg + 2*std
        return laps.filter { $0.lapTime > upper }
    }

    func averageDeviationFromBest(laps: [StoredLap]) -> Double {
        guard let best = laps.map({ $0.lapTime }).min() else { return 0 }
        let diffs = laps.map { $0.lapTime - best }
        return diffs.average ?? 0
    }

    // Paprasta interpretacija UI'ui
    func interpretScore(_ score: Double) -> (level: String, color: Color, message: String) {
        switch score {
        case 80...:
            return ("Excellent", .green, "Very consistent lap times.")
        case 60..<80:
            return ("Good", .teal, "Solid consistency with room to improve.")
        case 40..<60:
            return ("Average", .yellow, "Fluctuating pace; focus on repeatability.")
        default:
            return ("Low", .orange, "Large variance; review lines, braking and traffic.")
        }
    }
}

// MARK: - maži helperiai
private extension Array where Element == TimeInterval {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
    var std: Double? {
        guard let mean = average else { return nil }
        let v = map { pow($0 - mean, 2) }.reduce(0, +) / Double(count)
        return sqrt(v)
    }
}