//
//  DashboardView.swift
//  Prune
//

import Photos
import SwiftUI

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
                    .cardBackground()

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
                                value: ByteCountFormatter.formatFileSize(decisionStore.totalStorageFreed),
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
                    .cardBackground()
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
                .frame(width: 816) 

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
                .frame(width: 816) 

                Spacer()
            }
            .padding(.top, 16)

            // Photo Count Chart
            HStack {
                Spacer()

                PhotoCountChartView(
                    photoLibrary: photoLibrary
                )
                .frame(width: 816) 

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
