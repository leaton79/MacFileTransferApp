//
//  FileListView.swift
//  MacFileTransferApp
//

import SwiftUI
import UniformTypeIdentifiers

/// Simple list view showing file names and icons
struct FileListView: View {
    let items: [FileItem]
    let selectedItems: Set<FileItem>
    let onSelect: (FileItem, Bool) -> Void
    let onOpen: (FileItem) -> Void
    var onDelete: ((FileItem) -> Void)? = nil
    var onRename: ((FileItem) -> Void)? = nil
    
    var body: some View {
        List(items) { item in
            HStack(spacing: 12) {
                Image(systemName: item.iconName)
                    .foregroundColor(item.isDirectory ? .blue : .primary)
                    .frame(width: 20)
                
                Text(item.name)
                    .lineLimit(1)
                
                Spacer()
                
                // Show file size for non-directories
                if !item.isDirectory {
                    Text(item.formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .background(
                selectedItems.contains(item) ?
                    Color.accentColor.opacity(0.2) : Color.clear
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
        .listStyle(.plain)
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
