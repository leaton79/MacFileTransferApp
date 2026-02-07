//
//  FileBrowserViewModel.swift
//  MacFileTransferApp
//

import Foundation
import Combine

/// View model for a single file browser pane
class FileBrowserViewModel: ObservableObject {
    @Published var currentURL: URL
    @Published var items: [FileItem] = []
    @Published var selectedItems: Set<FileItem> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fileService = FileSystemService.shared
    private var navigationHistory: [URL] = []
    private var historyIndex: Int = -1
    
    init(startingURL: URL? = nil) {
        self.currentURL = startingURL ?? fileService.getUserHome()
        loadContents()
    }
    
    // MARK: - Navigation
    
    /// Navigate to a specific URL
    func navigate(to url: URL) {
        // Add to history if not navigating back/forward
        if historyIndex < navigationHistory.count - 1 {
            navigationHistory.removeSubrange((historyIndex + 1)...)
        }
        navigationHistory.append(currentURL)
        historyIndex = navigationHistory.count - 1
        
        currentURL = url
        selectedItems.removeAll()
        loadContents()
    }
    
    /// Navigate into selected folder
    func navigateIntoSelected() {
        guard let firstSelected = selectedItems.first,
              firstSelected.isDirectory else { return }
        navigate(to: firstSelected.url)
    }
    
    /// Go to parent directory
    func navigateUp() {
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        navigate(to: parent)
    }
    
    /// Go back in navigation history
    func goBack() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        currentURL = navigationHistory[historyIndex]
        selectedItems.removeAll()
        loadContents()
    }
    
    /// Go forward in navigation history
    func goForward() {
        guard historyIndex < navigationHistory.count - 1 else { return }
        historyIndex += 1
        currentURL = navigationHistory[historyIndex]
        selectedItems.removeAll()
        loadContents()
    }
    
    /// Check if can go back
    var canGoBack: Bool {
        historyIndex > 0
    }
    
    /// Check if can go forward
    var canGoForward: Bool {
        historyIndex < navigationHistory.count - 1
    }
    
    // MARK: - Content Loading
    
    /// Reload current directory contents
    func loadContents() {
        isLoading = true
        errorMessage = nil
        
        // Load on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let contents = self.fileService.contentsOfDirectory(at: self.currentURL)
            
            DispatchQueue.main.async {
                self.items = contents
                self.isLoading = false
            }
        }
    }
    
    /// Refresh current view
    func refresh() {
        selectedItems.removeAll()
        loadContents()
    }
    
    // MARK: - Selection
    
    /// Toggle selection for an item
    func toggleSelection(_ item: FileItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    /// Select all items
    func selectAll() {
        selectedItems = Set(items)
    }
    
    /// Clear selection
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    /// Check if item is selected
    func isSelected(_ item: FileItem) -> Bool {
        selectedItems.contains(item)
    }
    
    // MARK: - File Operations
    
    /// Delete selected items
    func deleteSelected() {
        for item in selectedItems {
            do {
                try fileService.deleteItem(at: item.url)
            } catch {
                errorMessage = "Failed to delete \(item.name): \(error.localizedDescription)"
            }
        }
        selectedItems.removeAll()
        loadContents()
    }
    
    /// Create new folder in current directory
    func createFolder(named name: String) {
        let folderURL = currentURL.appendingPathComponent(name)
        
        do {
            try fileService.createDirectory(at: folderURL)
            loadContents()
        } catch {
            errorMessage = "Failed to create folder: \(error.localizedDescription)"
        }
    }
}
