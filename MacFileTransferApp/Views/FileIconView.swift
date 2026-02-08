//
//  FileIconView.swift
//  MacFileTransferApp
//

import SwiftUI
import UniformTypeIdentifiers

/// Grid view showing files as large icons
struct FileIconView: View {
    let items: [FileItem]
    let selectedItems: Set<FileItem>
    let onSelect: (FileItem, Bool) -> Void
    let onOpen: (FileItem) -> Void
    var onDelete: ((FileItem) -> Void)? = nil
    var onRename: ((FileItem) -> Void)? = nil
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 48))
                            .foregroundColor(item.isDirectory ? .blue : .primary)
                            .frame(width: 80, height: 60)
                        
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
                    .gesture(
                        TapGesture(count: 2).onEnded { onOpen(item) }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 1).onEnded {
                            let cmdHeld = NSEvent.modifierFlags.contains(.command)
                            onSelect(item, cmdHeld)
                        }
                    )
                    .onDrag {
                        if item.url.isFileURL {
                            return NSItemProvider(object: item.url as NSURL)
                        }
                        return NSItemProvider()
                    }
                    .contextMenu { itemContextMenu(for: item) }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func itemContextMenu(for item: FileItem) -> some View {
        Button { onOpen(item) } label: {
            Label("Open", systemImage: "arrow.right.circle")
        }
        Divider()
        Button { onRename?(item) } label: {
            Label("Rename…", systemImage: "pencil")
        }
        Divider()
        Button(role: .destructive) { onDelete?(item) } label: {
            Label("Move to Trash", systemImage: "trash")
        }
        Divider()
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        } label: {
            Label("Copy Path", systemImage: "doc.on.doc")
        }
    }
}
