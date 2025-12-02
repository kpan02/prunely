//
//  DashboardView.swift
//  Prune
//

import SwiftUI
import Photos

struct DashboardView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    @State private var totalPhotos: Int = 0
    @State private var isLoadingTotal = true
    
    private var reviewedCount: Int {
        decisionStore.archivedPhotoIDs.count + decisionStore.trashedPhotoIDs.count
    }
    
    private var unreviewedCount: Int {
        max(0, totalPhotos - reviewedCount)
    }
    
    private var reviewPercentage: Double {
        guard totalPhotos > 0 else { return 0 }
        return Double(reviewedCount) / Double(totalPhotos) * 100
    }
    
    private var cleanedPercentage: Double {
        let originalLibrarySize = totalPhotos + decisionStore.totalPhotosDeleted
        guard originalLibrarySize > 0 else { return 0 }
        return Double(decisionStore.totalPhotosDeleted) / Double(originalLibrarySize) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.system(size: 28, weight: .semibold))
                }
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // Cards
            HStack {
                Spacer()
                
                HStack(alignment: .top, spacing: 16) {
                // Overview Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Overview")
                        .font(.system(size: 20, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        OverviewStatRow(
                            label: "Total Photos",
                            value: isLoadingTotal ? "..." : formatNumber(totalPhotos),
                            icon: "photo.on.rectangle",
                            color: .blue
                        )
                        
                        OverviewStatRow(
                            label: "Reviewed",
                            value: formatNumber(reviewedCount),
                            subtitle: totalPhotos > 0 ? String(format: "%.2f%%", reviewPercentage) : nil,
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        OverviewStatRow(
                            label: "Unreviewed",
                            value: isLoadingTotal ? "..." : formatNumber(unreviewedCount),
                            subtitle: totalPhotos > 0 ? String(format: "%.2f%%", 100 - reviewPercentage) : nil,
                            icon: "circle",
                            color: .orange
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 400, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xF2F7FD))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                
                // Deletion Statistics Card
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pruned")
                        .font(.system(size: 20, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DeletionStatRow(
                            label: "Photos Deleted",
                            value: formatNumber(decisionStore.totalPhotosDeleted),
                            icon: "trash.fill",
                            color: .red
                        )
                        
                        DeletionStatRow(
                            label: "Storage Saved",
                            value: formatFileSize(decisionStore.totalStorageFreed),
                            icon: "externaldrive.fill",
                            color: .blue
                        )
                        
                        DeletionStatRow(
                            label: "Library Cleaned",
                            value: isLoadingTotal ? "..." : String(format: "%.2f%%", cleanedPercentage),
                            icon: "scissors",
                            color: .purple
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 400, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xF2F7FD))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                }
                
                Spacer()
            }
            
            // Progress Heatmap
            HStack {
                Spacer()
                
                ProgressHeatmapView(
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
                .frame(width: 816) // 400 + 16 + 400
                
                Spacer()
            }
            .padding(.top, 16)
            
            // Top Unreviewed Months
            HStack {
                Spacer()
                
                TopUnreviewedMonthsView(
                    photoLibrary: photoLibrary,
                    decisionStore: decisionStore
                )
                .frame(width: 816) // 400 + 16 + 400
                
                Spacer()
            }
            .padding(.top, 16)
            
            // Photo Count Chart
            HStack {
                Spacer()
                
                PhotoCountChartView(
                    photoLibrary: photoLibrary
                )
                .frame(width: 816) // 400 + 16 + 400
                
                Spacer()
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .onAppear {
            calculateTotalPhotos()
        }
    }
    
    private func calculateTotalPhotos() {
        guard isLoadingTotal else { return }
        
        // Calculate total photo count on background thread
        Task.detached(priority: .userInitiated) {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let results = PHAsset.fetchAssets(with: fetchOptions)
            let count = results.count
            
            await MainActor.run {
                totalPhotos = count
                isLoadingTotal = false
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct OverviewStatRow: View {
    let label: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 24, alignment: .leading)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 8)
            
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                
                if let subtitle = subtitle {
                    Text("(\(subtitle))")
                        .font(.system(size: 14))
                        .foregroundStyle(color)
                }
            }
        }
    }
}

struct DeletionStatRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            
            Spacer(minLength: 8)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
}

enum MonthProgressStatus {
    case empty
    case unreviewed
    case inProgress
    case done
}

struct ProgressHeatmapView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    @State private var monthData: [String: MonthProgressStatus] = [:] // Key: "YYYY-MM"
    @State private var years: [Int] = []
    @State private var isLoading = true
    
    private let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Progress")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: Color.green.opacity(0.7), label: "Done")
                    LegendItem(color: Color.yellow.opacity(0.6), label: "In Progress")
                    LegendItem(color: Color.gray.opacity(0.4), label: "Unreviewed")
                }
            }
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 8) {
                        // Year labels column
                        VStack(alignment: .trailing, spacing: 6) {
                            // Month header row
                            Text("")
                                .frame(width: 50, height: 24)
                            
                            ForEach(years, id: \.self) { year in
                                Text(String(format: "%d", year))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 50, height: 20, alignment: .trailing)
                            }
                        }
                        
                        // Month columns
                        ForEach(Array(months.enumerated()), id: \.offset) { monthIndex, monthName in
                            VStack(alignment: .center, spacing: 6) {
                                // Month header
                                Text(monthName)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24, height: 24)
                                
                                // Year cells for this month
                                ForEach(years, id: \.self) { year in
                                    let key = "\(year)-\(String(format: "%02d", monthIndex + 1))"
                                    let status = monthData[key] ?? .empty
                                    
                                    HeatmapCell(status: status)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 816)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xF2F7FD))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            calculateProgress()
        }
        .onChange(of: decisionStore.archivedPhotoIDs.count) { _, _ in
            calculateProgress()
        }
        .onChange(of: decisionStore.trashedPhotoIDs.count) { _, _ in
            calculateProgress()
        }
    }
    
    private func colorForStatus(_ status: MonthProgressStatus) -> Color {
        switch status {
        case .empty:
            return Color.white.opacity(0.3)
        case .unreviewed:
            return Color.gray.opacity(0.3)
        case .inProgress:
            return Color.yellow.opacity(0.6)
        case .done:
            return Color.green.opacity(0.7)
        }
    }
    
    private func calculateProgress() {
        isLoading = true
        
        // Get reviewed IDs on main actor first
        let reviewedIDs = decisionStore.archivedPhotoIDs.union(decisionStore.trashedPhotoIDs)
        
        Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            var yearSet: Set<Int> = []
            
            // Fetch all photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let results = PHAsset.fetchAssets(with: fetchOptions)
            
            // Group photos by year-month
            var monthPhotos: [String: [PHAsset]] = [:]
            
            results.enumerateObjects { asset, _, _ in
                guard let creationDate = asset.creationDate else { return }
                
                let components = calendar.dateComponents([.year, .month], from: creationDate)
                guard let year = components.year, let month = components.month else { return }
                
                let key = "\(year)-\(String(format: "%02d", month))"
                
                if monthPhotos[key] == nil {
                    monthPhotos[key] = []
                }
                monthPhotos[key]?.append(asset)
                yearSet.insert(year)
            }
            
            // Calculate status for each month
            var finalData: [String: MonthProgressStatus] = [:]
            
            for (key, photos) in monthPhotos {
                let reviewedCount = photos.filter { photo in
                    reviewedIDs.contains(photo.localIdentifier)
                }.count
                
                let totalCount = photos.count
                
                if totalCount == 0 {
                    finalData[key] = .empty
                } else if reviewedCount == 0 {
                    finalData[key] = .unreviewed
                } else if reviewedCount < totalCount {
                    finalData[key] = .inProgress
                } else {
                    finalData[key] = .done
                }
            }
            
            // Fill in empty months for all year-month combinations
            let sortedYears = Array(yearSet).sorted(by: >) // Reverse chronological order (most recent first)
            for year in sortedYears {
                for month in 1...12 {
                    let key = "\(year)-\(String(format: "%02d", month))"
                    if finalData[key] == nil {
                        finalData[key] = .empty
                    }
                }
            }
            
            // Capture final values before MainActor.run
            let finalMonthData = finalData
            let finalYears = sortedYears
            
            // Update UI on main actor
            await MainActor.run {
                self.monthData = finalMonthData
                self.years = finalYears
                self.isLoading = false
            }
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }
}

struct HeatmapCell: View {
    let status: MonthProgressStatus
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(colorForStatus(status))
            .frame(width: 24, height: 20)
    }
    
    private func colorForStatus(_ status: MonthProgressStatus) -> Color {
        switch status {
        case .empty:
            return Color.white.opacity(0.3)
        case .unreviewed:
            return Color.gray.opacity(0.3)
        case .inProgress:
            return Color.yellow.opacity(0.6)
        case .done:
            return Color.green.opacity(0.7)
        }
    }
}

enum ChartViewMode: String, CaseIterable {
    case year = "Year"
    case month = "Month"
}

struct ChartDataPoint: Identifiable {
    let id: String
    let label: String
    let count: Int
    let date: Date
}

struct PhotoCountChartView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    
    @State private var viewMode: ChartViewMode = .year
    @State private var selectedYear: Int? = nil
    @State private var dataPoints: [ChartDataPoint] = []
    @State private var isLoading = true
    @State private var maxCount: Int = 0
    @State private var hoveredBar: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Photos")
                        .font(.system(size: 20, weight: .semibold))
                    
                    if viewMode == .month, let selectedYear = selectedYear {
                        HStack(spacing: 6) {
                            Button {
                                // Go back to year view
                                self.selectedYear = nil
                                self.viewMode = .year
                                calculateData()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.plain)
                            
                            Text(String(format: "%d", selectedYear))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // View mode dropdown
                Picker("View", selection: $viewMode) {
                    ForEach(ChartViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
                .onChange(of: viewMode) { _, newMode in
                    // Reset selected year when switching back to year view
                    if newMode == .year {
                        selectedYear = nil
                    }
                    calculateData()
                }
            }
            
            ZStack {
                // Always render the chart structure to prevent layout shifts
                if dataPoints.isEmpty && !isLoading {
                    Text("No data available")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: chartHeight + 30)
                } else {
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(alignment: .bottom, spacing: 8) {
                            // Y-axis labels
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(yAxisLabels, id: \.self) { label in
                                    Text(label)
                                        .font(.system(size: 9))
                                        .foregroundStyle(.secondary)
                                        .frame(height: safeYAxisRowHeight, alignment: .top)
                                }
                            }
                            .frame(width: 40, height: chartHeight)
                            
                            // Chart bars
                            VStack(alignment: .leading, spacing: 4) {
                                // Chart area with bars
                                HStack(alignment: .bottom, spacing: 4) {
                                    ForEach(dataPoints) { point in
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.blue.opacity(0.7))
                                            .frame(width: barWidth, height: barHeight(for: point.count))
                                            .overlay {
                                                if hoveredBar == point.id {
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .stroke(Color.blue, lineWidth: 2)
                                                }
                                            }
                                            .onTapGesture {
                                                handleBarClick(point)
                                            }
                                            .onHover { hovering in
                                                hoveredBar = hovering ? point.id : nil
                                            }
                                            .help("\(point.label): \(point.count) photos")
                                    }
                                }
                                .frame(height: chartHeight, alignment: .bottom)
                                
                                // X-axis labels below bars
                                HStack(spacing: 4) {
                                    ForEach(dataPoints) { point in
                                        Text(point.label)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                            .frame(width: barWidth)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Loading overlay
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: chartHeight + 30)
                        .background(Color(hex: 0xF2F7FD).opacity(0.8))
                }
            }
            .frame(minHeight: chartHeight + 30)
        }
        .padding(16)
        .frame(maxWidth: 816)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xF2F7FD))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            calculateData()
        }
    }
    
    private let barWidth: CGFloat = 30
    private let chartHeight: CGFloat = 250
    
    private var safeYAxisRowHeight: CGFloat {
        // Ensure we never divide by zero and always return a finite, non-negative height
        let rows = max(1, yAxisLabels.count - 1)
        let raw = chartHeight / CGFloat(rows)
        if raw.isFinite && raw > 0 { return raw }
        return chartHeight 
    }
    
    private var yAxisLabels: [String] {
        guard maxCount > 0 else { return ["0"] }
        // Round up maxCount to next nice number for better visualization
        let roundedMax = roundUpAxis(maxCount)
        let step = max(1, roundedMax / 5)
        return (0...5).reversed().map { "\($0 * step)" }
    }
    
    // Return the original value (as yAxisMax), but always round up to the next integer if not already an integer.
    // Add a small margin (e.g., 5%) to keep bars from touching the top.
    private func roundUpAxis(_ value: Int) -> Int {
        guard value > 0 else { return 1 }
        let margin = max(1, Int(Double(value) * 0.05))
        return value + margin
    }
    
    private var yAxisMax: Int {
        guard maxCount > 0 else { return 1 }
        return roundUpAxis(maxCount)
    }
    
    private func barHeight(for count: Int) -> CGFloat {
        let max = yAxisMax
        guard max > 0 else { return 0 }
        return CGFloat(count) / CGFloat(max) * chartHeight
    }
    
    private func handleBarClick(_ point: ChartDataPoint) {
        switch viewMode {
        case .year:
            // Click year -> zoom to months
            if let year = Int(point.label) {
                selectedYear = year
                viewMode = .month
                calculateData()
            }
        case .month:
            // Month bars are not clickable for further navigation
            break
        }
    }
    
    private func calculateData() {
        isLoading = true
        
        // Capture values before entering background task
        let currentViewMode = viewMode
        let currentSelectedYear = selectedYear
        
        Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            var points: [ChartDataPoint] = []
            var max: Int = 0
            
            // Fetch all photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let results = PHAsset.fetchAssets(with: fetchOptions)
            
            switch currentViewMode {
            case .year:
                // Group by year
                var yearCounts: [Int: Int] = [:]
                results.enumerateObjects { asset, _, _ in
                    guard let creationDate = asset.creationDate else { return }
                    let year = calendar.component(.year, from: creationDate)
                    yearCounts[year, default: 0] += 1
                }
                
                let sortedYears = yearCounts.keys.sorted(by: >)
                for year in sortedYears {
                    let count = yearCounts[year] ?? 0
                    max = Swift.max(max, count)
                    if let date = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) {
                        points.append(ChartDataPoint(
                            id: "year-\(year)",
                            label: "\(year)",
                            count: count,
                            date: date
                        ))
                    }
                }
                
            case .month:
                // Group by month (chronological)
                var monthCounts: [String: (count: Int, date: Date)] = [:]
                
                results.enumerateObjects { asset, _, _ in
                    guard let creationDate = asset.creationDate else { return }
                    let components = calendar.dateComponents([.year, .month], from: creationDate)
                    guard let year = components.year, let month = components.month else { return }
                    
                    // Filter by selected year if zoomed
                    if let currentSelectedYear = currentSelectedYear, year != currentSelectedYear {
                        return
                    }
                    
                    let key = "\(year)-\(String(format: "%02d", month))"
                    if monthCounts[key] == nil {
                        monthCounts[key] = (count: 0, date: calendar.date(from: components) ?? creationDate)
                    }
                    monthCounts[key]?.count += 1
                }
                
                // Sort: reverse chronological if general view, chronological if year-specific
                let sortedMonths = currentSelectedYear != nil 
                    ? monthCounts.sorted { $0.value.date < $1.value.date }
                    : monthCounts.sorted { $0.value.date > $1.value.date }
                
                let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                
                for (key, value) in sortedMonths {
                    let components = calendar.dateComponents([.year, .month], from: value.date)
                    if let year = components.year, let month = components.month {
                        let label: String
                        if currentSelectedYear != nil {
                            // Year-specific view: use month name
                            label = monthNames[month - 1]
                        } else {
                            // General view: use M/YY format (e.g., "1/13" or "11/24")
                            label = "\(month)/\(String(format: "%02d", year % 100))"
                        }
                        max = Swift.max(max, value.count)
                        points.append(ChartDataPoint(
                            id: "month-\(key)",
                            label: label,
                            count: value.count,
                            date: value.date
                        ))
                    }
                }
            }
            
            let finalPoints = points
            let finalMax = max
            
            await MainActor.run {
                self.dataPoints = finalPoints
                self.maxCount = finalMax
                self.isLoading = false
            }
        }
    }
}

struct UnreviewedMonth: Identifiable {
    let id: String
    let label: String
    let unreviewedCount: Int
    let totalCount: Int
}

struct TopUnreviewedMonthsView: View {
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    @State private var topMonths: [UnreviewedMonth] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biggest Months")
                .font(.system(size: 20, weight: .semibold))
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else if topMonths.isEmpty {
                Text("No unreviewed photos")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(topMonths.enumerated()), id: \.element.id) { index, month in
                        HStack(spacing: 12) {
                            // Rank number
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 24, alignment: .trailing)
                            
                            // Month label
                            Text(month.label)
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            // Unreviewed count
                            Text("\(month.unreviewedCount) Unreviewed")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 816)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: 0xF2F7FD))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            calculateTopMonths()
        }
        .onChange(of: decisionStore.archivedPhotoIDs.count) { _, _ in
            calculateTopMonths()
        }
        .onChange(of: decisionStore.trashedPhotoIDs.count) { _, _ in
            calculateTopMonths()
        }
    }
    
    private func calculateTopMonths() {
        isLoading = true
        
        // Get reviewed IDs on main actor first
        let reviewedIDs = decisionStore.archivedPhotoIDs.union(decisionStore.trashedPhotoIDs)
        
        Task.detached(priority: .userInitiated) {
            let calendar = Calendar.current
            var monthData: [String: (total: Int, unreviewed: Int, date: Date)] = [:]
            
            // Fetch all photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let results = PHAsset.fetchAssets(with: fetchOptions)
            
            // Group photos by month and count unreviewed
            results.enumerateObjects { asset, _, _ in
                guard let creationDate = asset.creationDate else { return }
                let components = calendar.dateComponents([.year, .month], from: creationDate)
                guard let year = components.year, let month = components.month else { return }
                
                let key = "\(year)-\(String(format: "%02d", month))"
                
                if monthData[key] == nil {
                    monthData[key] = (total: 0, unreviewed: 0, date: calendar.date(from: components) ?? creationDate)
                }
                
                monthData[key]?.total += 1
                
                if !reviewedIDs.contains(asset.localIdentifier) {
                    monthData[key]?.unreviewed += 1
                }
            }
            
            // Convert to array and sort by unreviewed count (descending)
            let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            let sortedMonths = monthData
                .filter { $0.value.unreviewed > 0 } 
                .sorted { $0.value.unreviewed > $1.value.unreviewed } 
                .prefix(5) 
                .map { key, value in
                    let components = calendar.dateComponents([.year, .month], from: value.date)
                    let year = components.year ?? 0
                    let month = components.month ?? 1
                    let label = "\(monthNames[month - 1]) \(year)"
                    
                    return UnreviewedMonth(
                        id: key,
                        label: label,
                        unreviewedCount: value.unreviewed,
                        totalCount: value.total
                    )
                }
            
            let finalMonths = Array(sortedMonths)
            
            await MainActor.run {
                self.topMonths = finalMonths
                self.isLoading = false
            }
        }
    }
}

