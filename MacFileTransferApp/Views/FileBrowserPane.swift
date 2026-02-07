//
//  FileBrowserPane.swift
//  MacFileTransferApp
//

import SwiftUI

enum ViewMode {
    case icons
    case list
    case details
}

/// Single file browser pane with toolbar and view switching
struct FileBrowserPane: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @State private var viewMode: ViewMode = .list
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    var body: some View {
            HSplitView {
                // Sidebar
                SidebarView(viewModel: viewModel)
                
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
                
                // Action buttons
                Button(action: { showingNewFolderAlert = true }) {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Create new folder")
                
                Button(action: { viewModel.refresh() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh folder contents")
                
                if !viewModel.selectedItems.isEmpty {
                    Button(action: { viewModel.deleteSelected() }) {
                        Image(systemName: "trash")
                    }
                    .help("Move selected items to trash")
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    
    // MARK: - Address Bar
    
    private var addressBar: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.blue)
            
            Text(viewModel.currentURL.path)
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
                onSelect: { viewModel.toggleSelection($0) },
                onOpen: { handleOpen($0) }
            )
            
        case .list:
            FileListView(
                items: viewModel.items,
                selectedItems: viewModel.selectedItems,
                onSelect: { viewModel.toggleSelection($0) },
                onOpen: { handleOpen($0) }
            )
            
        case .details:
                    FileDetailsView(
                        items: viewModel.items,
                        selectedItems: viewModel.selectedItems,
                        onSelect: { viewModel.toggleSelection($0) },
                        onOpen: { handleOpen($0) }
                    )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("This folder is empty")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func handleOpen(_ item: FileItem) {
        if item.isDirectory {
            viewModel.navigate(to: item.url)
        } else {
            // Open file with default app
            NSWorkspace.shared.open(item.url)
        }
    }
}
