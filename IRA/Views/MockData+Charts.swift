//
//  MockData+Charts.swift
//  IRA
//
//  Mock data for chart previews
//  Add this extension to your Models/Session.swift or Models/Lap.swift
//

import Foundation

extension Session {
    static func mockSession() -> Session {
        Session(
            id: UUID(),
            date: Date(),
            vehicle: "FA 2025 IAME X30",
            racer: "Troy",
            track: "Circuit Osona",
            laps: [Lap.mockLap()]
        )
    }
}

extension Lap {
    static func mockLap() -> Lap {
        // Generate realistic telemetry points for a ~60 second lap
        let pointCount = 1200 // 60 seconds * 20Hz
        var points: [TelemetryPoint] = []
        
        for i in 0..<pointCount {
            let t = Double(i) * 0.05 // 20Hz = 0.05s intervals
            let distance = Double(i) * 8.0 // ~8m per sample = ~9.6km total
            let angle = Double(i) * 0.02 // Varying angle for realistic curves
            
            // Realistic speed variation (40-120 km/h)
            let baseSpeed = 80.0 + 30.0 * sin(angle)
            
            // Realistic acceleration (-1.5G to +1.0G)
            let latAcc = 0.8 * sin(angle * 1.5)
            let lonAcc = 0.5 * cos(angle * 2.0)
            
            // Realistic RPM (8000-13000)
            let rpm = 10500 + Int(2000.0 * sin(angle))
            
            // Realistic temperatures
            let exhaustTemp = 480.0 + 60.0 * abs(sin(angle * 0.5))
            let waterTemp = 62.0 + 8.0 * abs(cos(angle * 0.3))
            
            let point = TelemetryPoint(
                id: UUID(),
                time: t,
                distance: distance,
                loggerTemp: 45.0,
                internalBattery: 12.6,
                speed: baseSpeed,
                satellites: 12,
                latitude: 41.8339 + 0.001 * cos(angle),
                longitude: 2.0436 + 0.001 * sin(angle),
                altitude: 450.0,
                heading: angle * 57.2958,
                slope: 1.0 * sin(angle * 0.3),
                latAcc: latAcc,
                lonAcc: lonAcc,
                gyro: 15.0 * sin(angle),
                radius: 50.0,
                posAccuracy: 2.0,
                speedAccuracy: 0.5,
                rpm: rpm,
                exhaustTemp: exhaustTemp,
                waterTemp: waterTemp,
                accelX: latAcc,
                accelY: lonAcc,
                accelZ: 9.8,
                gyroX: 5.0 * sin(angle),
                gyroY: 3.0 * cos(angle),
                gyroZ: 1.0
            )
            
            points.append(point)
        }
        
        return Lap(
            id: UUID(),
            lapNumber: 1,
            time: 62.456,
            telemetryPoints: points
        )
    }
}
