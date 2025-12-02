//
//  ContentView.swift
//  Prune
//

import SwiftUI
import Photos

struct ContentView: View {
    @StateObject private var photoLibrary = PhotoLibraryManager()
    @StateObject private var decisionStore = PhotoDecisionStore()
    @State private var selectedTab: SidebarTab = .media
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Custom Sidebar
                Sidebar(selectedTab: $selectedTab, decisionStore: decisionStore)
                    .padding(.leading, 12)
                    .padding(.vertical, 12)
                
                // Main Content
                Group {
                    switch photoLibrary.authorizationStatus {
                    case .authorized, .limited:
                        TabContentView(selectedTab: selectedTab, photoLibrary: photoLibrary, decisionStore: decisionStore)
                        
                    case .denied, .restricted:
                        VStack(spacing: 20) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.red)
                            Text("Photo Library Access Denied")
                                .font(.title2)
                            Text("Enable access in System Settings > Privacy & Security > Photos")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        
                    case .notDetermined:
                        VStack(spacing: 20) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            Text("Prune needs access to your Photos")
                                .font(.title2)
                            Button("Grant Access") {
                                photoLibrary.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                        
                    @unknown default:
                        Text("Unknown status")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 700, minHeight: 450)
            .background(Color(hex: 0xFEFFFC)) // background color for the main content
            .toolbar(.hidden)
        }
        .onAppear {
            photoLibrary.checkAuthorizationStatus()
            if photoLibrary.authorizationStatus == .authorized || photoLibrary.authorizationStatus == .limited {
                photoLibrary.fetchAlbums()
            }
        }
    }
}

struct TabContentView: View {
    let selectedTab: SidebarTab
    @ObservedObject var photoLibrary: PhotoLibraryManager
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                // Library tabs
                case .media:
                    MediaGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .albums:
                    AlbumsGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .months:
                    MonthsGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                // Utility tabs
                case .trash:
                    TrashGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .dashboard:
                    DashboardView(photoLibrary: photoLibrary, decisionStore: decisionStore)
                case .archive:
                    ArchiveGridView(photoLibrary: photoLibrary, decisionStore: decisionStore, columns: columns)
                case .help:
                    UtilityPlaceholderView(title: "Help", icon: "questionmark.circle", description: "Get help using Prune")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    ContentView()
}

