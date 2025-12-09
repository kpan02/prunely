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
    case help = "Guide"
    
    var icon: String {
        switch self {
        case .media: return "photo.on.rectangle"
        case .albums: return "square.stack.3d.up.fill"
        case .months: return "calendar"
        case .trash: return "trash"
        case .dashboard: return "chart.bar.fill"
        case .archive: return "archivebox.fill"
        case .help: return "checkmark.seal.fill"
        }
    }
    
    var section: SidebarSection {
        switch self {
        case .help:
            return .guide
        case .media, .albums, .months:
            return .library
        case .trash, .dashboard, .archive:
            return .utilities
        }
    }
    
    static var guideTabs: [SidebarTab] {
        allCases.filter { $0.section == .guide }
    }
    
    static var libraryTabs: [SidebarTab] {
        allCases.filter { $0.section == .library }
    }
    
    static var utilityTabs: [SidebarTab] {
        allCases.filter { $0.section == .utilities }
    }
}

enum SidebarSection: String {
    case guide = "Guide"
    case library = "Library"
    case utilities = "Utilities"
}

