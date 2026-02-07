//
//  FileListView.swift
//  MacFileTransferApp
//

import SwiftUI

/// Simple list view showing file names and icons
struct FileListView: View {
    let items: [FileItem]
    let selectedItems: Set<FileItem>
    let onSelect: (FileItem) -> Void
    let onOpen: (FileItem) -> Void
    
    var body: some View {
        List(items) { item in
            HStack(spacing: 12) {
                // Icon
                Image(systemName: item.iconName)
                    .foregroundColor(item.isDirectory ? .blue : .primary)
                    .frame(width: 20)
                
                // Name
                Text(item.name)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .background(
                selectedItems.contains(item) ?
                    Color.accentColor.opacity(0.2) : Color.clear
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(item)
            }
            .onTapGesture(count: 2) {
                onOpen(item)
            }
        }
        .listStyle(.plain)
    }
}
