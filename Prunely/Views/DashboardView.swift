//
//  DashboardView.swift
//  Prunely
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
        VStack(alignment: .leading, spacing: 12) {
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
                    HStack(alignment: .top, spacing: 10) {
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

