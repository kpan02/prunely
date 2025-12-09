//
//  GuideView.swift
//  Prune
//

import SwiftUI
import AppKit

struct GuideView: View {
    // MARK: - Layout Constants
    
    // Font Sizes
    private let sectionHeadingSize: CGFloat = 24
    private let subsectionHeadingSize: CGFloat = 24
    private let subheadingSize: CGFloat = 20
    private let bodyTextSize: CGFloat = 16
    
    // Spacing
    private let sectionSpacing: CGFloat = 40
    private let sectionInternalSpacing: CGFloat = 10
    private let nestedBulletSpacing: CGFloat = 0
    private let subsectionTopPadding: CGFloat = 8
    private let hStackSpacing: CGFloat = 8

    // Bullet Point Spacing
    private let bulletIndent: CGFloat = 10
    private let bulletSecondaryIndent: CGFloat = 30
    private let bulletToTextSpacing: CGFloat = 8
    private let bulletListSpacing: CGFloat = 10

    // Layout
    private let maxContentWidth: CGFloat = 700
    private let logoSize: CGFloat = 120
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: sectionSpacing) {
                Spacer()
                    .frame(height: 30) // top padding

                // Welcome to Prune
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    // Logo
                    HStack {
                        Spacer()
                        Group {
                            if let appIcon = NSImage(named: "AppIcon") ?? NSImage(named: NSImage.applicationIconName) {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: logoSize, height: logoSize)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 30)
                    
                    Text("Welcome to Prune")
                        .font(.system(size: 28, weight: .semibold))
                    
                    Text("Prune is a macOS app designed to help you review and clean your photo library efficiently.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Requirements
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Requirements")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune only works with photos in your Mac's Photos library. Please enable iCloud Photos to sync your iPhone photos to your Mac.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("Note: Prune only reviews photos. Videos are excluded.")
                        .font(.system(size: 14))
                        .italic()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Container for Photo Library Views, Reviewing Photos, Managing Your Decisions, and Dashboard
                VStack(alignment: .leading, spacing: sectionSpacing+5) {
                // Photo Library Views
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Photo Library Views")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune organizes your photos in three ways to suit different workflows:")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: bulletListSpacing) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: bodyTextSize))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: bodyTextSize, alignment: .leading)
                            Text("**Media**: Default Apple albums like Recents, Favorites, Screenshots")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: bodyTextSize))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: bodyTextSize, alignment: .leading)
                            Text("**Albums**: User-created albums")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: bodyTextSize))
                                .foregroundStyle(.black)
                                .frame(width: 20, height: bodyTextSize, alignment: .leading)
                            Text("**Months**: Your entire photo library organized by month and year")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.leading, 0)
                }
                
                // Photo Review Mode
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Reviewing Photos")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Click any album to start reviewing photos")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)

                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Review each photo in sequence using the **Keep** or **Delete** actions")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)
                        
                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("↪")
                                .font(.system(size: bodyTextSize))
                            Text("Photos you keep go to **Archive**; photos you delete go to **Trash**")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletSecondaryIndent)

                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Use **arrow keys** to speed through (← → to move, ↑ to Keep, ↓ to Delete)")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)
                        
                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Changed your mind? You can **Clear** a decision anytime")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)
                        
                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Turn on **Hide Reviewed** to see only photos you haven't reviewed yet")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)
                        
                        HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                            Text("•")
                                .font(.system(size: bodyTextSize))
                            Text("Use the filmstrip to browse all photos and see your decisions")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, bulletIndent)
                    }
                    .padding(.leading, 0)
                }
                
                // Managing Your Decisions
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Managing Your Decisions")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Prune has two holding areas for your review decisions. Nothing is permanently deleted until you choose.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Archive subsection
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Archive")
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)
                        
                        Text("Photos you mark as **Keep** go to Archive")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: bulletListSpacing) {
                            Text("• Archived photos are automatically hidden when you enable **Hide Reviewed** in the photo review mode")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• Restore individual photos from Archive, or restore all to reset your entire progress")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• To unarchive specific months or albums: go to Months or Albums view, toggle **Hide Reviewed Albums** (top right), then hover over the album to reveal the **Unarchive Album** button.")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 0)
                    }
                    
                    // Trash subsection
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Trash")
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)
                        
                        Text("Photos you mark as **Delete** go to Trash")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: bulletListSpacing) {
                            Text("• Restore individual photos, or restore all from Trash")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("• **Empty Trash** to permanently delete all trashed photos. They'll be sent to Recently Deleted in your Photos library (standard Photos behavior)")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 0)
                    }
                }
                
                // Dashboard
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Dashboard")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    Text("Track your review progress and photo library statistics")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: 0xF2F7FD))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                )
                
                // Data & Privacy
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Data & Privacy")
                        .font(.system(size: sectionHeadingSize, weight: .semibold))
                    
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Prune needs Photos library access to read and manage your photos. You can control this anytime in System Settings > Privacy & Security > Photos.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("**Prune never stores, uploads, or shares your photos.** They are accessed directly from your Photos library through Apple’s Photos framework.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Prune saves only your review decisions (which photos you kept or deleted), and it stores them locally on your Mac. This data is stored in ~/Library/Application Support/Prune/decisions.json and never leaves your device. This file only contains photo IDs, no images or metadata.")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // GitHub link
                HStack(alignment: .top, spacing: hStackSpacing) {
                    Text("🤓")
                        .font(.system(size: bodyTextSize))
                    HStack(spacing: nestedBulletSpacing) {
                        Text("Interested in this project? Check out the repo here: ")
                            .font(.system(size: bodyTextSize))
                        Link("https://github.com/kpan02/prune", destination: URL(string: "https://github.com/kpan02/prune")!)
                            .font(.system(size: bodyTextSize))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 40)

            Spacer()
                .frame(height: 10)
            }
            .frame(maxWidth: maxContentWidth) // Constrain width for centered, readable content
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GuideView()
}

