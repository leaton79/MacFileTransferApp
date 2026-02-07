//
//  FileSystemService.swift
//  MacFileTransferApp
//

import Foundation
import Combine

/// Handles file system operations (read, copy, move, delete)
class FileSystemService: ObservableObject {
    static let shared = FileSystemService()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - Reading Files
    
    /// Get contents of a directory
    func contentsOfDirectory(at url: URL) -> [FileItem] {
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .contentTypeKey
                ],
                options: [.skipsHiddenFiles]
            )
            
            // Convert URLs to FileItems, filter out nils
            let items = urls.compactMap { FileItem(url: $0) }
            
            // Sort: folders first, then alphabetically
            return items.sorted { item1, item2 in
                if item1.isDirectory != item2.isDirectory {
                    return item1.isDirectory
                }
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
            
        } catch {
            print("Error reading directory \(url.path): \(error)")
            return []
        }
    }
    
    /// Get list of volumes (drives)
    func getVolumes() -> [FileItem] {
        let volumeURLs = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey],
            options: [.skipHiddenVolumes]
        ) ?? []
        
        return volumeURLs.compactMap { FileItem(url: $0) }
    }
    
    /// Get user's home directory
    func getUserHome() -> URL {
        fileManager.homeDirectoryForCurrentUser
    }
    
    /// Get common user folders (Documents, Downloads, etc.)
    func getCommonLocations() -> [FileItem] {
        let locations: [FileManager.SearchPathDirectory] = [
            .documentDirectory,
            .downloadsDirectory,
            .desktopDirectory,
            .picturesDirectory,
            .musicDirectory,
            .moviesDirectory
        ]
        
        return locations.compactMap { searchPath in
            guard let url = fileManager.urls(for: searchPath, in: .userDomainMask).first else {
                return nil
            }
            return FileItem(url: url)
        }
    }
    
    // MARK: - File Operations
    
    /// Copy file or folder
    func copyItem(from source: URL, to destination: URL) throws {
        try fileManager.copyItem(at: source, to: destination)
    }
    
    /// Move file or folder
    func moveItem(from source: URL, to destination: URL) throws {
        try fileManager.moveItem(at: source, to: destination)
    }
    
    /// Delete file or folder
    func deleteItem(at url: URL) throws {
        try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
    
    /// Create new folder
    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    /// Check if file/folder exists
    func itemExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
    
    /// Generate unique filename if destination exists
    func uniqueDestination(for url: URL, in directory: URL) -> URL {
        var destination = directory.appendingPathComponent(url.lastPathComponent)
        var counter = 1
        
        let nameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let fileExtension = url.pathExtension
        
        while itemExists(at: destination) {
            let newName: String
            if fileExtension.isEmpty {
                newName = "\(nameWithoutExtension) \(counter)"
            } else {
                newName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            destination = directory.appendingPathComponent(newName)
            counter += 1
        }
        
        return destination
    }
}
