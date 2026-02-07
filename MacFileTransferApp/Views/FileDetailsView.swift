//
//  FileDetailsView.swift
//  MacFileTransferApp
//

import SwiftUI

/// Details view with sortable and customizable columns
struct FileDetailsView: View {
    let items: [FileItem]
    let selectedItems: Set<FileItem>
    let onSelect: (FileItem) -> Void
    let onOpen: (FileItem) -> Void
    
    @StateObject private var columnConfig = ColumnConfiguration()
    @State private var sortOrder = [KeyPathComparator(\FileItem.name)]
    @State private var showingColumnPicker = false
    
    var sortedItems: [FileItem] {
        items.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Column chooser button
            HStack {
                Spacer()
                
                Button(action: { showingColumnPicker.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Columns")
                            .font(.caption)
                    }
                }
                .buttonStyle(.bordered)
                .help("Choose which columns to display")
                .padding(8)
                .popover(isPresented: $showingColumnPicker, arrowEdge: .bottom) {
                    columnPickerView
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Table
            Table(sortedItems, selection: .constant(selectedItemIDs), sortOrder: $sortOrder) {
                // Name column (always visible)
                TableColumn("Name") { item in
                    HStack(spacing: 6) {
                        Image(systemName: item.iconName)
                            .foregroundColor(item.isDirectory ? .blue : .primary)
                            .frame(width: 16)
                        Text(item.name)
                    }
                }
                .width(min: DetailColumn.name.width.min,
                       ideal: DetailColumn.name.width.ideal,
                       max: DetailColumn.name.width.max)
                
                // Size column
                if columnConfig.isVisible(.size) {
                    TableColumn("Size", value: \.formattedSize)
                        .width(min: DetailColumn.size.width.min,
                               ideal: DetailColumn.size.width.ideal,
                               max: DetailColumn.size.width.max)
                }
                
                // Type column
                if columnConfig.isVisible(.type) {
                    TableColumn("Type", value: \.typeDescription)
                        .width(min: DetailColumn.type.width.min,
                               ideal: DetailColumn.type.width.ideal,
                               max: DetailColumn.type.width.max)
                }
                
                // Kind column
                if columnConfig.isVisible(.kind) {
                    TableColumn("Kind", value: \.kind)
                        .width(min: DetailColumn.kind.width.min,
                               ideal: DetailColumn.kind.width.ideal,
                               max: DetailColumn.kind.width.max)
                }
                
                // Date Modified column
                if columnConfig.isVisible(.dateModified) {
                    TableColumn("Date Modified") { item in
                        Text("\(item.modificationDate.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .width(min: DetailColumn.dateModified.width.min,
                           ideal: DetailColumn.dateModified.width.ideal,
                           max: DetailColumn.dateModified.width.max)
                }
                
                // Date Created column
                if columnConfig.isVisible(.dateCreated) {
                    TableColumn("Date Created") { item in
                        Text("\(item.creationDate.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .width(min: DetailColumn.dateCreated.width.min,
                           ideal: DetailColumn.dateCreated.width.ideal,
                           max: DetailColumn.dateCreated.width.max)
                }
                
                // Date Accessed column
                if columnConfig.isVisible(.dateAccessed) {
                    TableColumn("Date Accessed") { item in
                        Text("\(item.accessDate.formatted(date: .abbreviated, time: .shortened))")
                    }
                    .width(min: DetailColumn.dateAccessed.width.min,
                           ideal: DetailColumn.dateAccessed.width.ideal,
                           max: DetailColumn.dateAccessed.width.max)
                }
                
                // Permissions column
                if columnConfig.isVisible(.permissions) {
                    TableColumn("Permissions", value: \.permissions)
                        .width(min: DetailColumn.permissions.width.min,
                               ideal: DetailColumn.permissions.width.ideal,
                               max: DetailColumn.permissions.width.max)
                }
                
                // Owner column
                if columnConfig.isVisible(.owner) {
                    TableColumn("Owner", value: \.owner)
                        .width(min: DetailColumn.owner.width.min,
                               ideal: DetailColumn.owner.width.ideal,
                               max: DetailColumn.owner.width.max)
                }
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .onTapGesture(count: 2) {
                if let first = selectedItems.first {
                    onOpen(first)
                }
            }
            .onChange(of: selectedItemIDs) { oldValue, newValue in
                let newlySelected = newValue.subtracting(oldValue)
                if let id = newlySelected.first,
                   let item = items.first(where: { $0.id == id }) {
                    onSelect(item)
                }
            }
        }
    }
    
    private var selectedItemIDs: Set<FileItem.ID> {
        Set(selectedItems.map { $0.id })
    }
    
    private var columnPickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Show Columns")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(DetailColumn.allCases) { column in
                Toggle(column.rawValue, isOn: Binding(
                    get: { columnConfig.isVisible(column) },
                    set: { _ in columnConfig.toggle(column) }
                ))
                .disabled(column == .name) // Name always visible
            }
        }
        .padding()
        .frame(width: 200)
    }
}
