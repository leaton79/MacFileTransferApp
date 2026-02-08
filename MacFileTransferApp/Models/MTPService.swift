//
//  MTPService.swift
//  MacFileTransferApp
//
//  MTP device management - wraps libmtp C library for Swift
//

import Foundation
import Combine

// MARK: - Data Models

/// Represents a connected Android MTP device
struct MTPDevice: Identifiable, Hashable {
    let id: String              // Unique identifier (serial number or bus/dev)
    let name: String            // Friendly name, e.g. "Google Pixel 8 Pro"
    let manufacturer: String
    let model: String
    let serialNumber: String
    let storageInfo: [MTPStorageInfo]
    
    /// Display name — uses friendly name if available, falls back to model
    var displayName: String {
        if !name.isEmpty { return name }
        if !model.isEmpty { return "\(manufacturer) \(model)".trimmingCharacters(in: .whitespaces) }
        return "Android Device"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MTPDevice, rhs: MTPDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Storage partition on an MTP device (internal storage, SD card, etc.)
struct MTPStorageInfo: Identifiable {
    let id: UInt32              // MTP storage ID
    let description: String     // "Internal Storage", "SD Card", etc.
    let totalBytes: UInt64
    let freeBytes: UInt64
    
    var usedBytes: UInt64 { totalBytes - freeBytes }
    
    var totalFormatted: String { ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file) }
    var freeFormatted: String { ByteCountFormatter.string(fromByteCount: Int64(freeBytes), countStyle: .file) }
}

/// Represents a file or folder on the MTP device
struct MTPFile: Identifiable {
    let id: UInt32              // MTP object ID
    let parentID: UInt32        // Parent folder's object ID
    let storageID: UInt32       // Which storage partition
    let name: String
    let size: UInt64
    let modificationDate: Date
    let isDirectory: Bool
}

// MARK: - MTP Service

/// Manages MTP device connections and operations.
/// Uses libmtp C library via bridging header.
class MTPService: ObservableObject {
    
    /// List of currently detected devices
    @Published var detectedDevices: [MTPDevice] = []
    
    /// Whether a scan is in progress
    @Published var isScanning: Bool = false
    
    /// Last error message, if any
    @Published var lastError: String?
    
    /// Currently connected device handle
    private var deviceHandle: UnsafeMutablePointer<LIBMTP_mtpdevice_t>? = nil
    
    /// Whether we have an active device connection
    var isConnected: Bool { deviceHandle != nil }
    
    /// ID of currently connected device
    private var connectedDeviceID: String?
    
    // MARK: - Initialization
    
    init() {
        LIBMTP_Init()
    }
    
    deinit {
        disconnect()
    }
    
    // MARK: - Device Detection
    
    /// Scans for connected MTP devices.
    func scanForDevices() {
        isScanning = true
        lastError = nil
        
        var rawDevices: UnsafeMutablePointer<LIBMTP_raw_device_t>? = nil
        var numDevices: Int32 = 0
        
        let detectResult = LIBMTP_Detect_Raw_Devices(&rawDevices, &numDevices)
        
        defer {
            if rawDevices != nil {
                free(rawDevices)
            }
            isScanning = false
        }
        
        guard detectResult == LIBMTP_ERROR_NONE else {
            if detectResult == LIBMTP_ERROR_NO_DEVICE_ATTACHED {
                detectedDevices = []
            } else {
                lastError = "MTP detection error (code: \(detectResult.rawValue))"
            }
            return
        }
        
        guard numDevices > 0, let devices = rawDevices else {
            detectedDevices = []
            return
        }
        
        var foundDevices: [MTPDevice] = []
        
        for i in 0..<Int(numDevices) {
            var rawDevice = devices[i]
            
            guard let handle = LIBMTP_Open_Raw_Device_Uncached(&rawDevice) else {
                continue
            }
            
            let friendlyName = readMTPString(LIBMTP_Get_Friendlyname(handle))
            let manufacturer = readMTPString(LIBMTP_Get_Manufacturername(handle))
            let model = readMTPString(LIBMTP_Get_Modelname(handle))
            let serial = readMTPString(LIBMTP_Get_Serialnumber(handle))
            
            let deviceID: String
            if !serial.isEmpty {
                deviceID = serial
            } else {
                deviceID = "bus\(rawDevice.bus_location)-dev\(rawDevice.devnum)"
            }
            
            let storageList = readStorageInfo(from: handle)
            
            let device = MTPDevice(
                id: deviceID,
                name: friendlyName,
                manufacturer: manufacturer,
                model: model,
                serialNumber: serial,
                storageInfo: storageList
            )
            
            foundDevices.append(device)
            LIBMTP_Release_Device(handle)
        }
        
        detectedDevices = foundDevices
    }
    
    // MARK: - Device Connection
    
    /// Connects to a specific device for browsing and transfers.
    @discardableResult
    func connect(to device: MTPDevice) -> Bool {
        disconnect()
        
        var rawDevices: UnsafeMutablePointer<LIBMTP_raw_device_t>? = nil
        var numDevices: Int32 = 0
        
        let detectResult = LIBMTP_Detect_Raw_Devices(&rawDevices, &numDevices)
        
        defer {
            if rawDevices != nil {
                free(rawDevices)
            }
        }
        
        guard detectResult == LIBMTP_ERROR_NONE, numDevices > 0, let devices = rawDevices else {
            lastError = "Device not found. It may have been disconnected."
            return false
        }
        
        for i in 0..<Int(numDevices) {
            var rawDevice = devices[i]
            guard let handle = LIBMTP_Open_Raw_Device_Uncached(&rawDevice) else {
                continue
            }
            
            let serial = readMTPString(LIBMTP_Get_Serialnumber(handle))
            let candidateID = !serial.isEmpty ? serial : "bus\(rawDevice.bus_location)-dev\(rawDevice.devnum)"
            
            if candidateID == device.id {
                deviceHandle = handle
                connectedDeviceID = device.id
                LIBMTP_Get_Storage(handle, 0)
                return true
            } else {
                LIBMTP_Release_Device(handle)
            }
        }
        
        lastError = "Could not reconnect to \(device.displayName). Try unplugging and reconnecting."
        return false
    }
    
    /// Disconnects from the currently connected device.
    func disconnect() {
        if let handle = deviceHandle {
            LIBMTP_Release_Device(handle)
            deviceHandle = nil
            connectedDeviceID = nil
        }
    }
    
    // MARK: - File Browsing
    
    /// Lists files and folders in a given folder on the connected device.
    /// Use parentID = 0xFFFFFFFF for root. Use storageID = 0 for all partitions.
    func listFiles(storageID: UInt32 = 0, parentID: UInt32 = 0xFFFFFFFF) -> [MTPFile] {
        guard let handle = deviceHandle else {
            lastError = "No device connected"
            return []
        }
        
        var files: [MTPFile] = []
        var filePtr = LIBMTP_Get_Files_And_Folders(handle, storageID, parentID)
        
        while let current = filePtr {
            let name: String
            if let fnamePtr = current.pointee.filename {
                name = String(cString: fnamePtr)
            } else {
                name = "(unnamed)"
            }
            
            let isDir = (current.pointee.filetype == LIBMTP_FILETYPE_FOLDER)
            let modDate = Date(timeIntervalSince1970: TimeInterval(current.pointee.modificationdate))
            
            let mtpFile = MTPFile(
                id: current.pointee.item_id,
                parentID: current.pointee.parent_id,
                storageID: current.pointee.storage_id,
                name: name,
                size: current.pointee.filesize,
                modificationDate: modDate,
                isDirectory: isDir
            )
            files.append(mtpFile)
            
            let next = current.pointee.next
            LIBMTP_destroy_file_t(current)
            filePtr = next
        }
        
        // Sort: folders first, then alphabetical
        files.sort { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        
        return files
    }
    
    // MARK: - File Transfers
    
    /// Downloads a file from the MTP device to a local path.
    func downloadFile(_ file: MTPFile, to localURL: URL) -> Bool {
        guard let handle = deviceHandle else {
            lastError = "No device connected"
            return false
        }
        
        let result = LIBMTP_Get_File_To_File(handle, file.id, localURL.path, nil, nil)
        
        if result != 0 {
            lastError = "Download failed for \(file.name)"
            clearErrors()
            return false
        }
        return true
    }
    
    /// Uploads a local file to the MTP device.
    func uploadFile(from localURL: URL, storageID: UInt32, parentID: UInt32) -> Bool {
        guard let handle = deviceHandle else {
            lastError = "No device connected"
            return false
        }
        
        let fileName = localURL.lastPathComponent
        
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: localURL.path),
              let fileSize = attrs[.size] as? UInt64 else {
            lastError = "Cannot read local file: \(fileName)"
            return false
        }
        
        guard let mtpFile = LIBMTP_new_file_t() else {
            lastError = "Failed to create MTP file structure"
            return false
        }
        
        mtpFile.pointee.filename = strdup(fileName)
        mtpFile.pointee.filesize = fileSize
        mtpFile.pointee.filetype = LIBMTP_FILETYPE_UNKNOWN
        mtpFile.pointee.storage_id = storageID
        mtpFile.pointee.parent_id = parentID
        
        let result = LIBMTP_Send_File_From_File(handle, localURL.path, mtpFile, nil, nil)
        
        LIBMTP_destroy_file_t(mtpFile)
        
        if result != 0 {
            lastError = "Upload failed for \(fileName)"
            clearErrors()
            return false
        }
        return true
    }
    
    /// Deletes a file or folder from the connected MTP device.
    func deleteFile(_ file: MTPFile) -> Bool {
        guard let handle = deviceHandle else {
            lastError = "No device connected"
            return false
        }
        
        let result = LIBMTP_Delete_Object(handle, file.id)
        if result != 0 {
            lastError = "Delete failed for \(file.name)"
            clearErrors()
            return false
        }
        return true
    }
    
    /// Creates a new folder on the MTP device. Returns new folder's object ID, or nil on failure.
    func createFolder(name: String, storageID: UInt32, parentID: UInt32) -> UInt32? {
        guard let handle = deviceHandle else {
            lastError = "No device connected"
            return nil
        }
        
        let nameCopy = strdup(name)
        let folderID = LIBMTP_Create_Folder(handle, nameCopy, parentID, storageID)
        free(nameCopy)
        
        if folderID == 0 {
            lastError = "Failed to create folder '\(name)'"
            clearErrors()
            return nil
        }
        return folderID
    }
    
    // MARK: - Private Helpers
    
    /// Reads a C string from libmtp (malloc'd), converts to Swift String, frees the C string.
    private func readMTPString(_ cString: UnsafeMutablePointer<CChar>?) -> String {
        guard let ptr = cString else { return "" }
        let result = String(cString: ptr)
        free(ptr)
        return result
    }
    
    /// Reads storage partitions from an open device handle.
    private func readStorageInfo(from handle: UnsafeMutablePointer<LIBMTP_mtpdevice_t>) -> [MTPStorageInfo] {
        LIBMTP_Get_Storage(handle, 0)
        
        var storageList: [MTPStorageInfo] = []
        var storagePtr = handle.pointee.storage
        
        while let storage = storagePtr {
            let desc: String
            if let descPtr = storage.pointee.StorageDescription {
                desc = String(cString: descPtr)
            } else {
                desc = "Storage"
            }
            
            let info = MTPStorageInfo(
                id: storage.pointee.id,
                description: desc,
                totalBytes: storage.pointee.MaxCapacity,
                freeBytes: storage.pointee.FreeSpaceInBytes
            )
            storageList.append(info)
            storagePtr = storage.pointee.next
        }
        
        return storageList
    }
    
    /// Clears the libmtp error stack to prevent stale errors.
    private func clearErrors() {
        guard let handle = deviceHandle else { return }
        LIBMTP_Dump_Errorstack(handle)
        LIBMTP_Clear_Errorstack(handle)
    }
}
