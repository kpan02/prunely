//
//  Formatters.swift
//  Prune
//
//  Shared formatting utilities for numbers and file sizes.
//

import Foundation

extension ByteCountFormatter {
    static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

