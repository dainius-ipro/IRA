import SwiftUI
import Charts

struct LapTimesChart: View {
    let laps: [StoredLap]

    struct Point: Identifiable {
        let id = UUID()
        let idx: Int
        let time: Double
    }

    var points: [Point] {
        laps.enumerated().map { Point(idx: $0.offset+1, time: $0.element.lapTime) }
    }

    var body: some View {
        Chart(points) {
            LineMark(x: .value("Lap", $0.idx),
                     y: .value("Time", $0.time))
        }
        .frame(height: 180)
        .padding(.vertical, 4)
    }
}

struct StatisticsView: View {
    let laps: [StoredLap]
    var body: some View {
        let times = laps.map { $0.lapTime }
        let best = times.min() ?? 0
        let avg  = (times.reduce(0,+) / Double(max(times.count,1)))
        VStack(alignment: .leading, spacing: 6) {
            Text("Best: \(best, format: .number.precision(.fractionLength(3))) s")
            Text("Average: \(avg, format: .number.precision(.fractionLength(3))) s")
            Text("Laps: \(laps.count)")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct InterpretationView: View {
    let level: String
    let color: Color
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(level).bold()
            }
            Text(message)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}