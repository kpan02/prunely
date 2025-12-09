//
//  Sidebar.swift
//  Prune
//

import SwiftUI

struct Sidebar: View {
    @Binding var selectedTab: SidebarTab
    @ObservedObject var decisionStore: PhotoDecisionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Guide Section
            SidebarSectionHeader(title: "Guide")
            
            VStack(spacing: 2) {
                ForEach(SidebarTab.guideTabs, id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Library Section
            SidebarSectionHeader(title: "Library")
                .padding(.top, 20)
            
            VStack(spacing: 2) {
                ForEach(SidebarTab.libraryTabs, id: \.self) { tab in
                    SidebarItem(tab: tab, isSelected: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            
            // Utilities Section
            SidebarSectionHeader(title: "Utilities")
                .padding(.top, 20)
            
            VStack(spacing: 2) {
                ForEach(SidebarTab.utilityTabs, id: \.self) { tab in
                    SidebarItem(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        showBadge: tab == .trash && !decisionStore.trashedPhotoIDs.isEmpty
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 10)
            
            Spacer()
            
        }
        .padding(.top, 12)
        .frame(width: 180)
        .cardBackground()
    }
}

struct SidebarSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}

struct SidebarItem: View {
    let tab: SidebarTab
    let isSelected: Bool
    var showBadge: Bool = false
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if tab.icon.unicodeScalars.first?.properties.isEmoji == true {
                    Text(tab.icon)
                        .font(.system(size: 14))
                        .frame(width: 20)
                } else {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                }
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                Spacer()
                
                if showBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ? Color.accentColor.opacity(0.15) :
                        isHovered ? Color.primary.opacity(0.06) : Color.clear
                    )
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

