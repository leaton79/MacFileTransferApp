//
//  FileIconView.swift
//  MacFileTransferApp
//

import SwiftUI

/// Grid view showing files as large icons
struct FileIconView: View {
    let items: [FileItem]
    let selectedItems: Set<FileItem>
    let onSelect: (FileItem) -> Void
    let onOpen: (FileItem) -> Void
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 8) {
                        // Large icon
                        Image(systemName: item.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(item.isDirectory ? .blue : .primary)
                            .frame(width: 80, height: 60)
                        
                        // Name
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .frame(width: 100)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedItems.contains(item) ?
                                  Color.accentColor.opacity(0.2) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(item)
                    }
                    .onTapGesture(count: 2) {
                        onOpen(item)
                    }
                }
            }
            .padding()
        }
    }
}
