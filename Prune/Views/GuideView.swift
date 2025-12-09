//
//  GuideView.swift
//  Prune
//

import AppKit
import SwiftUI

struct GuideView: View {
    // MARK: - Layout Constants

    // Font Sizes
    private let bodyTextSize: CGFloat = 16
    private let sectionHeadingSize: CGFloat = 28
    private let featureHeadingSize: CGFloat = 24
    private let subsectionHeadingSize: CGFloat = 20

    // Spacing
    private let sectionSpacing: CGFloat = 45
    private let sectionInternalSpacing: CGFloat = 8
    private let nestedBulletSpacing: CGFloat = 0
    private let subsectionTopPadding: CGFloat = 8
    private let subsectionIndent: CGFloat = 20

    // Bullet Point Spacing
    private let bulletIndent: CGFloat = 10
    private let bulletSecondaryIndent: CGFloat = 30
    private let bulletToTextSpacing: CGFloat = 8
    private let bulletListSpacing: CGFloat = 10

    // Divider
    private let dividerPadding: CGFloat = 6

    // App Features Container Spacing
    private let appFeaturesSectionSpacing: CGFloat = 25

    // Layout
    private let maxContentWidth: CGFloat = 700
    private let logoSize: CGFloat = 130

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
                        .font(.system(size: sectionHeadingSize, weight: .semibold))

                    Text("Prune is a macOS app designed to help you review and clean your photo library efficiently.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Requirements
                VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                    Text("Requirements")
                        .font(.system(size: featureHeadingSize, weight: .semibold))

                    Text("Prune only works with photos in your Mac's Photos library. Please enable iCloud Photos to sync your iPhone photos to your Mac.")
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Note: Prune only reviews photos. Videos are excluded.")
                        .font(.system(size: 14))
                        .italic()
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Container for App Features
                VStack(alignment: .leading, spacing: appFeaturesSectionSpacing) {
                    // Header
                    HStack {
                        Spacer()
                        Text("Key Features")
                            .font(.system(size: 28, weight: .semibold))
                        Spacer()
                    }

                    // Photo Library Views
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Photo Library Views")
                            .font(.system(size: featureHeadingSize, weight: .semibold))

                        Text("Prune organizes your photos in three ways:")
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
                                Text("**Months**: Entire photo library organized by month and year")
                                    .font(.system(size: bodyTextSize))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.leading, 0)
                    }

                    // Divider
                    Divider()
                        .padding(.horizontal, dividerPadding)

                    // Photo Review Mode
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Reviewing Photos")
                            .font(.system(size: featureHeadingSize, weight: .semibold))

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
                                Text("Use **arrow keys** to speed through (← → to move, ↑ to Keep, ↓ to Delete)")
                                    .font(.system(size: bodyTextSize))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, bulletSecondaryIndent)

                            HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                Text("↪")
                                    .font(.system(size: bodyTextSize))
                                HStack(spacing: 0) {
                                    Text("Photos you keep go to **Archive** ")
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: bodyTextSize))
                                        .baselineOffset(-1)
                                    Text("; photos you delete go to **Trash** ")
                                    Image(systemName: "trash")
                                        .font(.system(size: bodyTextSize))
                                        .baselineOffset(-1)
                                }
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, bulletSecondaryIndent)

                            HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                Text("↪")
                                    .font(.system(size: bodyTextSize))
                                Text("Once you review a photo, that decision is remembered everywhere it appears (across all albums and views)")
                                    .font(.system(size: bodyTextSize))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.leading, bulletSecondaryIndent)

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

                    // Divider
                    Divider()
                        .padding(.horizontal, dividerPadding)

                    // Managing Your Decisions
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        Text("Managing Your Decisions")
                            .font(.system(size: featureHeadingSize, weight: .semibold))

                        Text("Prune has two holding areas for your review decisions:")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)

                        // Archive subsection
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Text("Archive")
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: subsectionHeadingSize))
                            }
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)

                            Text("Photos you **Keep** go to Archive")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                                HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                    Text("•")
                                        .font(.system(size: bodyTextSize))
                                    Text("Archived photos are automatically hidden when you enable **Hide Reviewed** in the photo review mode")
                                        .font(.system(size: bodyTextSize))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, bulletIndent)

                                HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                    Text("•")
                                        .font(.system(size: bodyTextSize))
                                    Text("Restore individual photos from Archive, or **Restore All** to reset your entire progress")
                                        .font(.system(size: bodyTextSize))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, bulletIndent)

                                HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                    Text("•")
                                        .font(.system(size: bodyTextSize))
                                    Text("To unarchive specific months or albums: go to Months or Albums view, toggle **Hide Reviewed Albums** (top right), then hover over the album to reveal the **Unarchive Album** button.")
                                        .font(.system(size: bodyTextSize))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, bulletIndent)
                            }
                            .padding(.leading, 0)
                        }
                        .padding(.leading, subsectionIndent)
                        .padding(.vertical, 10)

                        // Trash subsection
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Text("Trash")
                                Image(systemName: "trash")
                                    .font(.system(size: subsectionHeadingSize))
                            }
                            .font(.system(size: subsectionHeadingSize, weight: .semibold))
                            .padding(.top, subsectionTopPadding)

                            Text("Photos you **Delete** go to Trash")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                                HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                    Text("•")
                                        .font(.system(size: bodyTextSize))
                                    Text("**Empty Trash** to permanently delete all trashed photos. They'll be sent to Recently Deleted in your Photos library (standard Photos behavior)")
                                        .font(.system(size: bodyTextSize))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, bulletIndent)

                                HStack(alignment: .firstTextBaseline, spacing: bulletToTextSpacing) {
                                    Text("•")
                                        .font(.system(size: bodyTextSize))
                                    Text("Restore individual photos, or **Restore All** from Trash")
                                        .font(.system(size: bodyTextSize))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, bulletIndent)
                            }
                            .padding(.leading, 0)
                        }
                        .padding(.leading, subsectionIndent)
                    }

                    // Divider
                    Divider()
                        .padding(.horizontal, dividerPadding)

                    // Dashboard
                    VStack(alignment: .leading, spacing: sectionInternalSpacing) {
                        HStack(spacing: 8) {
                            Text("Dashboard")
                                .font(.system(size: featureHeadingSize, weight: .semibold))
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: featureHeadingSize - 5))
                        }

                        Text("Track your review progress and photo library statistics")
                            .font(.system(size: bodyTextSize))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .cardBackground()

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

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Prune only saves your review decisions (which photos you kept or deleted), and it stores them locally on your Mac. This data is stored in ~/Library/Application Support/Prune/decisions.json and never leaves your device. This file only contains photo IDs; no images or metadata.")
                                .font(.system(size: bodyTextSize))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.system(size: bodyTextSize))
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // GitHub link
                HStack(alignment: .top, spacing: 5) {
                    Text("🤓")
                        .font(.system(size: 14))
                    HStack(spacing: nestedBulletSpacing) {
                        Text("Interested in this project? Check out the repo: ")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Link("https://github.com/kpan02/prune", destination: URL(string: "https://github.com/kpan02/prune")!)
                            .font(.system(size: 14))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 25)
            }
            .frame(maxWidth: maxContentWidth) 
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GuideView()
}
