//
//  TrackMapView.swift
//  RaceAnalytics
//
//  Created by RaceAnalytics Team on 2025-11-07.
//  Epic 2: Track Visualization (IRA-12, IRA-13, IRA-14, IRA-15)
//

import SwiftUI
import MapKit

/// Interactive map view displaying GPS track with speed heatmap and beacon markers
/// Supports multiple laps, zoom/pan/rotation controls, and map type switching
struct TrackMapView: View {
    // MARK: - Properties
    
    let session: Session
    @State private var selectedLapIndex: Int = 0
    @State private var showHeatmap: Bool = true
    @State private var selectedMapType: MapTypeOption = .standard
    @State private var allowRotation: Bool = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // Helper enum for map type selection
    enum MapTypeOption: String, CaseIterable, Hashable {
        case standard = "Standard"
        case hybrid = "Satellite"
        case imagery = "Hybrid"
        
        var mapStyle: MapStyle {
            switch self {
            case .standard: return .standard
            case .hybrid: return .hybrid
            case .imagery: return .imagery
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var selectedLap: Lap? {
        guard selectedLapIndex < session.laps.count else { return nil }
        return session.laps[selectedLapIndex]
    }
    
    private var trackCoordinates: [CLLocationCoordinate2D] {
        guard let lap = selectedLap else { return [] }
        return lap.telemetryPoints
            .filter { $0.hasValidGPS } // Use built-in helper
            .compactMap { $0.coordinate } // Use built-in computed property
    }
    
    private var trackBounds: MKMapRect {
        guard !trackCoordinates.isEmpty else { return MKMapRect.null }
        
        var minLat = trackCoordinates[0].latitude
        var maxLat = trackCoordinates[0].latitude
        var minLon = trackCoordinates[0].longitude
        var maxLon = trackCoordinates[0].longitude
        
        for coord in trackCoordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        
        // Add 10% padding
        let latPadding = (maxLat - minLat) * 0.1
        let lonPadding = (maxLon - minLon) * 0.1
        
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: maxLat + latPadding,
            longitude: minLon - lonPadding
        ))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: minLat - latPadding,
            longitude: maxLon + lonPadding
        ))
        
        return MKMapRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(topLeft.x - bottomRight.x),
            height: abs(topLeft.y - bottomRight.y)
        )
    }
    
    private var beaconMarkers: [BeaconMarker] {
        guard let lap = selectedLap else { return [] }
        
        var markers: [BeaconMarker] = []
        var sectorNumber = 1
        var lastMarkerDistance: Double = 0
        
        for point in lap.telemetryPoints {
            // Skip invalid coordinates
            guard point.hasValidGPS, let coordinate = point.coordinate else { continue }
            
            // Space markers at least 50m apart
            if point.distance - lastMarkerDistance >= 50 {
                markers.append(BeaconMarker(
                    coordinate: coordinate,
                    sectorNumber: sectorNumber,
                    distance: point.distance
                ))
                sectorNumber += 1
                lastMarkerDistance = point.distance
            }
        }
        
        return markers
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Map Layer
            Map(position: $cameraPosition) {
                // GPS Track or Heatmap
                if showHeatmap {
                    ForEach(heatmapSegments, id: \.id) { segment in
                        MapPolyline(coordinates: segment.coordinates)
                            .stroke(segment.color, lineWidth: 4)
                    }
                } else {
                    MapPolyline(coordinates: trackCoordinates)
                        .stroke(.blue, lineWidth: 3)
                }
                
                // Beacon Markers
                ForEach(beaconMarkers) { marker in
                    Annotation(
                        "S\(marker.sectorNumber)",
                        coordinate: marker.coordinate
                    ) {
                        BeaconMarkerView(sectorNumber: marker.sectorNumber)
                    }
                }
            }
            .mapStyle(selectedMapType.mapStyle)
            .mapControlVisibility(.hidden)
            .onAppear {
                fitTrackToBounds()
            }
            
            // Controls Overlay
            VStack {
                // Top Controls
                HStack {
                    // Lap Selector
                    if session.laps.count > 1 {
                        lapSelector
                    }
                    
                    Spacer()
                    
                    // Map Type Picker
                    mapTypePicker
                }
                .padding()
                
                Spacer()
                
                // Bottom Controls
                HStack {
                    // Heatmap Toggle
                    heatmapToggle
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        // Rotation Toggle
                        rotationToggle
                        
                        // Fit Track Button
                        fitTrackButton
                    }
                }
                .padding()
                
                // Speed Legend (when heatmap active)
                if showHeatmap {
                    speedLegend
                        .padding(.bottom)
                }
            }
        }
        .onChange(of: selectedLapIndex) { _, _ in
            fitTrackToBounds()
        }
    }
    
    // MARK: - Heatmap Generation
    
    private var heatmapSegments: [HeatmapSegment] {
        guard let lap = selectedLap else { return [] }
        
        var segments: [HeatmapSegment] = []
        let points = lap.telemetryPoints.filter { $0.hasValidGPS }
        
        for i in 0..<(points.count - 1) {
            let start = points[i]
            let end = points[i + 1]
            
            // Skip if coordinates are invalid
            guard let startCoord = start.coordinate,
                  let endCoord = end.coordinate,
                  let startSpeed = start.speed,
                  let endSpeed = end.speed else {
                continue
            }
            
            let avgSpeed = (startSpeed + endSpeed) / 2
            let color = speedToColor(avgSpeed)
            
            let segment = HeatmapSegment(
                coordinates: [startCoord, endCoord],
                color: color,
                speed: avgSpeed
            )
            
            segments.append(segment)
        }
        
        return segments
    }
    
    private func speedToColor(_ speed: Double) -> Color {
        // Speed in km/h
        // Red: < 50 km/h
        // Yellow: 50-80 km/h
        // Green: > 80 km/h
        
        if speed < 50 {
            return .red
        } else if speed < 80 {
            // Interpolate between red and yellow
            let ratio = (speed - 50) / 30
            return Color(
                red: 1.0,
                green: ratio,
                blue: 0
            )
        } else {
            // Interpolate between yellow and green
            let ratio = min((speed - 80) / 30, 1.0)
            return Color(
                red: 1.0 - ratio,
                green: 1.0,
                blue: 0
            )
        }
    }
    
    // MARK: - UI Components
    
    private var lapSelector: some View {
        Menu {
            ForEach(session.laps.indices, id: \.self) { index in
                Button {
                    selectedLapIndex = index
                } label: {
                    HStack {
                        Text("Lap \(index + 1)")
                        if index == selectedLapIndex {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "flag.checkered")
                Text("Lap \(selectedLapIndex + 1)")
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private var mapTypePicker: some View {
        Menu {
            ForEach(MapTypeOption.allCases, id: \.self) { option in
                Button {
                    selectedMapType = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if selectedMapType == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "map")
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }
    
    private var heatmapToggle: some View {
        Button {
            showHeatmap.toggle()
        } label: {
            HStack {
                Image(systemName: showHeatmap ? "speedometer" : "speedometer.slash")
                Text(showHeatmap ? "Heatmap" : "Track")
            }
            .padding(8)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
    }
    
    private var rotationToggle: some View {
        Button {
            allowRotation.toggle()
        } label: {
            Image(systemName: allowRotation ? "rotate.3d" : "rotate.3d.slash")
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }
    
    private var fitTrackButton: some View {
        Button {
            withAnimation {
                fitTrackToBounds()
            }
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
        }
    }
    
    private var speedLegend: some View {
        HStack(spacing: 16) {
            LegendItem(color: .red, label: "< 50")
            LegendItem(color: .yellow, label: "50-80")
            LegendItem(color: .green, label: "> 80")
            Text("km/h")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    // MARK: - Helper Methods
    
    private func fitTrackToBounds() {
        guard !trackCoordinates.isEmpty else { return }
        
        let rect = trackBounds
        let span = MKCoordinateSpan(
            latitudeDelta: rect.size.height / 111000, // meters to degrees approximation
            longitudeDelta: rect.size.width / 111000
        )
        
        let center = CLLocationCoordinate2D(
            latitude: (trackCoordinates.map(\.latitude).min()! + trackCoordinates.map(\.latitude).max()!) / 2,
            longitude: (trackCoordinates.map(\.longitude).min()! + trackCoordinates.map(\.longitude).max()!) / 2
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

// MARK: - Supporting Types

struct HeatmapSegment: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let color: Color
    let speed: Double
}

struct BeaconMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let sectorNumber: Int
    let distance: Double
}

struct BeaconMarkerView: View {
    let sectorNumber: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 30, height: 30)
            
            Image(systemName: "flag.fill")
                .foregroundStyle(.red)
                .font(.system(size: 14))
            
            Text("\(sectorNumber)")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: 8)
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Track Map") {
    // Note: Session.preview has empty telemetry points
    // For real testing, import actual session data
    TrackMapView(session: Session.preview)
}
#endif
