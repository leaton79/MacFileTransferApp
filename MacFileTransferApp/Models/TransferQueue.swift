//
//  TransferQueue.swift
//  MacFileTransferApp
//

import Foundation
import Combine

/// Represents a single file transfer operation
struct TransferOperation: Identifiable {
    let id = UUID()
    let source: URL
    let destination: URL
    let type: TransferType
    var progress: Double = 0.0
    var status: TransferStatus = .pending
    var error: String?
    
    enum TransferType {
        case copy
        case move
    }
    
    enum TransferStatus {
        case pending
        case inProgress
        case completed
        case failed
    }
    
    var displayName: String {
        source.lastPathComponent
    }
}

/// Manages queued file transfers with progress tracking
class TransferQueue: ObservableObject {
    static let shared = TransferQueue()
    
    @Published var operations: [TransferOperation] = []
    @Published var isProcessing = false
    
    private let fileService = FileSystemService.shared
    private var currentTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Queue Management
    
    /// Add copy operation to queue
    func queueCopy(from source: URL, to destinationFolder: URL) {
        let destination = fileService.uniqueDestination(for: source, in: destinationFolder)
        let operation = TransferOperation(
            source: source,
            destination: destination,
            type: .copy
        )
        operations.append(operation)
        
        if !isProcessing {
            processQueue()
        }
    }
    
    /// Add move operation to queue
    func queueMove(from source: URL, to destinationFolder: URL) {
        let destination = fileService.uniqueDestination(for: source, in: destinationFolder)
        let operation = TransferOperation(
            source: source,
            destination: destination,
            type: .move
        )
        operations.append(operation)
        
        if !isProcessing {
            processQueue()
        }
    }
    
    /// Add multiple items to queue
    func queueMultiple(items: [FileItem], to destinationFolder: URL, type: TransferOperation.TransferType) {
        for item in items {
            let destination = fileService.uniqueDestination(for: item.url, in: destinationFolder)
            let operation = TransferOperation(
                source: item.url,
                destination: destination,
                type: type
            )
            operations.append(operation)
        }
        
        if !isProcessing {
            processQueue()
        }
    }
    
    /// Clear completed operations
    func clearCompleted() {
        operations.removeAll { $0.status == .completed }
    }
    
    /// Cancel all pending operations
    func cancelAll() {
        currentTask?.cancel()
        operations.removeAll { $0.status == .pending }
        isProcessing = false
    }
    
    // MARK: - Processing
    
    private func processQueue() {
        guard !isProcessing else { return }
        guard let nextIndex = operations.firstIndex(where: { $0.status == .pending }) else {
            isProcessing = false
            return
        }
        
        isProcessing = true
        operations[nextIndex].status = .inProgress
        
        currentTask = Task {
            await performTransfer(at: nextIndex)
            
            await MainActor.run {
                processQueue() // Process next item
            }
        }
    }
    
    private func performTransfer(at index: Int) async {
        let operation = operations[index]
        
        do {
            // Simulate progress for better UX (real progress tracking is complex)
            for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                await MainActor.run {
                    operations[index].progress = progress
                }
                try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            
            // Perform actual file operation
            switch operation.type {
            case .copy:
                try fileService.copyItem(from: operation.source, to: operation.destination)
            case .move:
                try fileService.moveItem(from: operation.source, to: operation.destination)
            }
            
            await MainActor.run {
                operations[index].status = .completed
                operations[index].progress = 1.0
            }
            
        } catch {
            await MainActor.run {
                operations[index].status = .failed
                operations[index].error = error.localizedDescription
            }
        }
    }
}
