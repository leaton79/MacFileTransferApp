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
    
    /// Whether we are currently browsing an MTP device
    @Published var isBrowsingMTP = false
    
    private let fileService = FileSystemService.shared
    
    /// Reference to MTP service (set when browsing Android device)
    var mtpService: MTPService?
    
    /// Currently connected MTP device
    var currentMTPDevice: MTPDevice?
    
    /// Current MTP storage ID being browsed
    private var currentStorageID: UInt32 = 0
    
    /// Current MTP parent folder ID (0xFFFFFFFF = root)
    private var currentParentID: UInt32 = 0xFFFFFFFF
    
    /// Maps FileItem IDs to MTP object IDs for navigation
    private var mtpObjectMap: [UUID: UInt32] = [:]
    
    /// Stack of parent IDs for MTP back navigation
    private var mtpParentStack: [UInt32] = []
    
    private var navigationHistory: [URL] = []
    private var historyIndex: Int = -1
    
    init(startingURL: URL? = nil) {
        self.currentURL = startingURL ?? fileService.getUserHome()
        loadContents()
    }
    
    // MARK: - Navigation
    
    /// Navigate to a specific URL
    func navigate(to url: URL) {
        // If we're navigating to a local path, exit MTP mode
        if url.isFileURL {
            isBrowsingMTP = false
            currentMTPDevice = nil
            mtpObjectMap.removeAll()
            mtpParentStack.removeAll()
        }
        
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
        if isBrowsingMTP {
            navigateMTPUp()
            return
        }
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        navigate(to: parent)
    }
    
    /// Go back in navigation history
    func goBack() {
        if isBrowsingMTP && !mtpParentStack.isEmpty {
            navigateMTPUp()
            return
        }
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
        if isBrowsingMTP {
            return !mtpParentStack.isEmpty
        }
        return historyIndex > 0
    }
    
    /// Check if can go forward
    var canGoForward: Bool {
        historyIndex < navigationHistory.count - 1
    }
    
    // MARK: - Content Loading
    
    /// Reload current directory contents
    func loadContents() {
        if isBrowsingMTP {
            loadMTPContents()
            return
        }
        
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
    
    /// Select an item. If exclusive is true, replaces selection. If false, toggles (for Cmd+click).
        func toggleSelection(_ item: FileItem) {
            // Called from Table view or legacy code — toggle behavior
            if selectedItems.contains(item) {
                selectedItems.remove(item)
            } else {
                selectedItems.insert(item)
            }
        }
        
        /// Single click: select only this item. Command+click: add/remove from selection.
        func selectItem(_ item: FileItem, addToSelection: Bool) {
            if addToSelection {
                // Command+click: toggle this item in/out
                if selectedItems.contains(item) {
                    selectedItems.remove(item)
                } else {
                    selectedItems.insert(item)
                }
            } else {
                // Normal click: select only this item
                selectedItems = [item]
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
    
    // MARK: - MTP Browsing
    
    /// Connect to an MTP device and show its root files
    func connectToMTPDevice(_ device: MTPDevice, service: MTPService) {
        mtpService = service
        currentMTPDevice = device
        isBrowsingMTP = true
        mtpObjectMap.removeAll()
        mtpParentStack.removeAll()
        currentStorageID = 0
        currentParentID = 0xFFFFFFFF
        
        // Connect to the device
        guard service.connect(to: device) else {
            errorMessage = service.lastError ?? "Failed to connect to \(device.displayName)"
            isBrowsingMTP = false
            return
        }
        
        // Set a virtual URL for display in the address bar
        currentURL = URL(string: "mtp://\(device.id)/")
            ?? URL(fileURLWithPath: "/mtp-device")
        
        selectedItems.removeAll()
        loadMTPContents()
    }
    
    /// Load file listing from the connected MTP device
    private func loadMTPContents() {
        guard let service = mtpService else {
            errorMessage = "MTP service not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        mtpObjectMap.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let mtpFiles = service.listFiles(
                storageID: self.currentStorageID,
                parentID: self.currentParentID
            )
            
            let deviceID = self.currentMTPDevice?.id ?? "unknown"
            var fileItems: [FileItem] = []
            var objectMap: [UUID: UInt32] = [:]
            
            for mtpFile in mtpFiles {
                let item = FileItem(mtpFile: mtpFile, deviceID: deviceID)
                fileItems.append(item)
                objectMap[item.id] = mtpFile.id
            }
            
            DispatchQueue.main.async {
                self.items = fileItems
                self.mtpObjectMap = objectMap
                self.isLoading = false
            }
        }
    }
    
    /// Navigate into an MTP folder
    func navigateIntoMTPFolder(_ item: FileItem) {
        guard let objectID = mtpObjectMap[item.id] else { return }
        
        // Push current parent onto stack for back navigation
        mtpParentStack.append(currentParentID)
        currentParentID = objectID
        
        // Update virtual URL for address bar
        if let deviceID = currentMTPDevice?.id {
            currentURL = URL(string: "mtp://\(deviceID)/\(item.name)".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
                ?? currentURL.appendingPathComponent(item.name)
        }
        
        selectedItems.removeAll()
        loadMTPContents()
    }
    
    /// Navigate up one level in MTP folder hierarchy
    private func navigateMTPUp() {
        guard !mtpParentStack.isEmpty else { return }
        currentParentID = mtpParentStack.removeLast()
        
        // Update virtual URL
        currentURL = currentURL.deletingLastPathComponent()
        
        selectedItems.removeAll()
        loadMTPContents()
    }
    
    /// Get the MTP object ID for a FileItem (used for transfers)
    func mtpObjectID(for item: FileItem) -> UInt32? {
        return mtpObjectMap[item.id]
    }
}
