//
//  FileBrowserPane.swift
//  MacFileTransferApp
//

import SwiftUI
import UniformTypeIdentifiers

enum ViewMode {
    case icons
    case list
    case details
}

/// Single file browser pane with toolbar and view switching
struct FileBrowserPane: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @ObservedObject var mtpService: MTPService
    @State private var viewMode: ViewMode = .list
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showingRenameAlert = false
    @State private var renameTarget: FileItem?
    @State private var renameNewName = ""
    @State private var isDropTargeted = false
    
    var body: some View {
            HSplitView {
                // Sidebar
                SidebarView(viewModel: viewModel, mtpService: mtpService)
                
                // Main content
                VStack(spacing: 0) {
                    // Toolbar
                    toolbar
                    
                    Divider()
                    
                    // Address bar
                    addressBar
                    
                    Divider()
                    
                    // Content area
                    if viewModel.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.items.isEmpty {
                        emptyState
                    } else {
                        contentView
                    }
                }
                .overlay(
                    // Visual feedback for drop target
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .opacity(isDropTargeted ? 1 : 0)
                )
                .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers: providers)
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder name", text: $newFolderName)
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
                Button("Create") {
                    if !newFolderName.isEmpty {
                        viewModel.createFolder(named: newFolderName)
                        newFolderName = ""
                    }
                }
            }
            .alert("Rename", isPresented: $showingRenameAlert) {
                TextField("New name", text: $renameNewName)
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                    renameNewName = ""
                }
                Button("Rename") {
                    if let item = renameTarget, !renameNewName.isEmpty {
                        performRename(item: item, newName: renameNewName)
                    }
                    renameTarget = nil
                    renameNewName = ""
                }
            } message: {
                if let item = renameTarget {
                    Text("Rename \"\(item.name)\" to:")
                }
            }
        }
    
    // MARK: - Drop Handling
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !viewModel.isBrowsingMTP else { return false }
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                guard let data = data as? Data,
                      let sourceURL = URL(dataRepresentation: data, relativeTo: nil) else { return }
                let destURL = viewModel.currentURL.appendingPathComponent(sourceURL.lastPathComponent)
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            // Skip if already exists at destination
                            return
                        }
                        try FileManager.default.copyItem(at: sourceURL, to: destURL)
                        DispatchQueue.main.async { viewModel.refresh() }
                    } catch {
                        print("Drop copy failed: \(error)")
                    }
                }
            }
        }
        return true
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
            HStack(spacing: 12) {
                // Navigation buttons
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.canGoBack)
                .help("Go back to previous folder")
                
                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canGoForward)
                .help("Go forward to next folder")
                
                Button(action: { viewModel.navigateUp() }) {
                    Image(systemName: "chevron.up")
                }
                .help("Go to parent folder")
                
                Divider()
                    .frame(height: 20)
                
                // View mode buttons
                Button(action: { viewMode = .icons }) {
                    Image(systemName: "square.grid.2x2")
                }
                .buttonStyle(.bordered)
                .tint(viewMode == .icons ? .accentColor : .gray)
                .help("Icon view")
                
                Button(action: { viewMode = .list }) {
                    Image(systemName: "list.bullet")
                }
                .buttonStyle(.bordered)
                .tint(viewMode == .list ? .accentColor : .gray)
                .help("List view")
                
                Button(action: { viewMode = .details }) {
                    Image(systemName: "tablecells")
                }
                .buttonStyle(.bordered)
                .tint(viewMode == .details ? .accentColor : .gray)
                .help("Details view with sortable columns")
                
                Spacer()
                
                // Action buttons — always visible
                Button(action: { showingNewFolderAlert = true }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Create new folder")
                
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh folder contents")
                
                Button(action: { viewModel.deleteSelected() }) {
                    Image(systemName: "trash")
                }
                .disabled(viewModel.selectedItems.isEmpty)
                .help("Move selected items to trash")
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    
    // MARK: - Address Bar
    
    private var addressBar: some View {
        HStack {
            Image(systemName: viewModel.isBrowsingMTP ? "apps.iphone" : "folder")
                .foregroundColor(viewModel.isBrowsingMTP ? .green : .blue)
            
            Text(viewModel.isBrowsingMTP
                 ? (viewModel.currentMTPDevice?.displayName ?? "Android Device")
                 : viewModel.currentURL.path)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            Text("\(viewModel.items.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !viewModel.selectedItems.isEmpty {
                Text("• \(viewModel.selectedItems.count) selected")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .icons:
            FileIconView(
                items: viewModel.items,
                selectedItems: viewModel.selectedItems,
                onSelect: { item, addToSelection in
                    viewModel.selectItem(item, addToSelection: addToSelection)
                },
                onOpen: { handleOpen($0) },
                onDelete: { handleDelete($0) },
                onRename: { handleRenameRequest($0) }
            )
            
        case .list:
            FileListView(
                items: viewModel.items,
                selectedItems: viewModel.selectedItems,
                onSelect: { item, addToSelection in
                    viewModel.selectItem(item, addToSelection: addToSelection)
                },
                onOpen: { handleOpen($0) },
                onDelete: { handleDelete($0) },
                onRename: { handleRenameRequest($0) }
            )
            
        case .details:
            FileDetailsView(
                items: viewModel.items,
                selectedItems: viewModel.selectedItems,
                onSelect: { viewModel.toggleSelection($0) },
                onOpen: { handleOpen($0) },
                onDelete: { handleDelete($0) },
                onRename: { handleRenameRequest($0) }
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: viewModel.isBrowsingMTP ? "apps.iphone" : "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(viewModel.isBrowsingMTP ? "No files found on device" : "This folder is empty")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func handleOpen(_ item: FileItem) {
        if viewModel.isBrowsingMTP {
            if item.isDirectory {
                viewModel.navigateIntoMTPFolder(item)
            }
        } else {
            if item.isDirectory {
                viewModel.navigate(to: item.url)
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }
    
    private func handleDelete(_ item: FileItem) {
        if viewModel.isBrowsingMTP {
            // MTP delete — future enhancement
        } else {
            do {
                try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                viewModel.selectedItems.remove(item)
                viewModel.refresh()
            } catch {
                viewModel.errorMessage = "Failed to delete \(item.name): \(error.localizedDescription)"
            }
        }
    }
    
    private func handleRenameRequest(_ item: FileItem) {
        renameTarget = item
        renameNewName = item.name
        showingRenameAlert = true
    }
    
    private func performRename(item: FileItem, newName: String) {
        guard !viewModel.isBrowsingMTP else { return }
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try FileManager.default.moveItem(at: item.url, to: newURL)
            viewModel.refresh()
        } catch {
            viewModel.errorMessage = "Failed to rename: \(error.localizedDescription)"
        }
    }
}
