//
//  SidebarTab.swift
//  Prune
//

import Foundation

enum SidebarTab: String, CaseIterable {
    // Library section
    case media = "Media"
    case albums = "Albums"
    case months = "Months"
    // Utilities section
    case trash = "Trash"
    case dashboard = "Dashboard"
    case archive = "Archive"
    case help = "Help"
    
    var icon: String {
        switch self {
        case .media: return "photo.on.rectangle"
        case .albums: return "square.stack.3d.up.fill"
        case .months: return "calendar"
        case .trash: return "trash"
        case .dashboard: return "chart.bar.fill"
        case .archive: return "archivebox.fill"
        case .help: return "questionmark.circle"
        }
    }
    
    var section: SidebarSection {
        switch self {
        case .media, .albums, .months:
            return .library
        case .trash, .dashboard, .archive, .help:
            return .utilities
        }
    }
    
    static var libraryTabs: [SidebarTab] {
        allCases.filter { $0.section == .library }
    }
    
    static var utilityTabs: [SidebarTab] {
        allCases.filter { $0.section == .utilities }
    }
}

enum SidebarSection: String {
    case library = "Library"
    case utilities = "Utilities"
}

