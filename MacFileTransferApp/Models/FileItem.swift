//
//  FileItem.swift
//  MacFileTransferApp
//

import Foundation
import UniformTypeIdentifiers

/// Represents a file or folder with metadata
struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    let isDirectory: Bool
    let modificationDate: Date
    let creationDate: Date
    let accessDate: Date
    let type: UTType?
    let permissions: String
    let owner: String
    
    /// Human-readable file size (e.g., "1.5 MB")
    var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    /// File extension (e.g., "txt", "jpg")
    var fileExtension: String {
        url.pathExtension.lowercased()
    }
    
    /// File type description (e.g., "JPEG Image")
    var typeDescription: String {
        type?.localizedDescription ?? "Unknown"
    }
    
    /// Kind (shorter description)
    var kind: String {
        if isDirectory {
            return "Folder"
        }
        if let ext = type?.preferredFilenameExtension?.uppercased(), !ext.isEmpty {
            return "\(ext) File"
        }
        return typeDescription
    }
    
    /// Icon name for SF Symbols
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        // Match common file types to icons
        guard let type = type else { return "doc.fill" }
        
        if type.conforms(to: .image) {
            return "photo.fill"
        } else if type.conforms(to: .movie) || type.conforms(to: .video) {
            return "film.fill"
        } else if type.conforms(to: .audio) {
            return "music.note"
        } else if type.conforms(to: .pdf) {
            return "doc.text.fill"
        } else if type.conforms(to: .plainText) {
            return "doc.plaintext.fill"
        } else if type.conforms(to: .archive) {
            return "doc.zipper"
        } else {
            return "doc.fill"
        }
    }
    
    /// Create FileItem from a URL
    init?(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .isDirectoryKey,
                .fileSizeKey,
                .contentModificationDateKey,
                .creationDateKey,
                .contentAccessDateKey,
                .contentTypeKey
            ])
            
            self.isDirectory = resourceValues.isDirectory ?? false
            self.size = Int64(resourceValues.fileSize ?? 0)
            self.modificationDate = resourceValues.contentModificationDate ?? Date()
            self.creationDate = resourceValues.creationDate ?? Date()
            self.accessDate = resourceValues.contentAccessDate ?? Date()
            self.type = resourceValues.contentType
            
            // Get file permissions
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let posixPermissions = attributes[.posixPermissions] as? NSNumber {
                let mode = posixPermissions.uint16Value
                self.permissions = String(format: "%o", mode)
            } else {
                self.permissions = "---"
            }
            
            // Get owner
            if let ownerName = attributes[.ownerAccountName] as? String {
                self.owner = ownerName
            } else {
                self.owner = "Unknown"
            }
            
        } catch {
            print("Error reading file attributes for \(url.path): \(error)")
            return nil
        }
    }
}
