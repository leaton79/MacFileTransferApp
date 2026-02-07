//
//  TransferStatusView.swift
//  MacFileTransferApp
//

import SwiftUI

/// Shows transfer queue and progress
struct TransferStatusView: View {
    @ObservedObject var queue = TransferQueue.shared
    @State private var isExpanded = true
    
    var body: some View {
        if !queue.operations.isEmpty {
            VStack(spacing: 0) {
                Divider()
                
                // Header
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                    
                    Text("Transfers")
                        .font(.headline)
                    
                    Spacer()
                    
                    if queue.isProcessing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 20, height: 20)
                    }
                    
                    Text("\(activeCount) active, \(completedCount) completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: { queue.clearCompleted() }) {
                        Text("Clear Completed")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(completedCount == 0)
                    
                    Button(action: { queue.cancelAll() }) {
                        Text("Cancel All")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!queue.isProcessing)
                    
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.down.circle" : "chevron.up.circle")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .contentShape(Rectangle())
                .onTapGesture {
                    isExpanded.toggle()
                }
                
                // Transfer list
                if isExpanded {
                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(queue.operations) { operation in
                                TransferRowView(operation: operation)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 150)
                    .background(Color(nsColor: .textBackgroundColor))
                }
            }
        }
    }
    
    private var activeCount: Int {
        queue.operations.filter {
            $0.status == .pending || $0.status == .inProgress
        }.count
    }
    
    private var completedCount: Int {
        queue.operations.filter { $0.status == .completed }.count
    }
}

/// Single transfer operation row
struct TransferRowView: View {
    let operation: TransferOperation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Status icon
                statusIcon
                
                // File name
                Text(operation.displayName)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)
                
                Spacer()
                
                // Type badge
                Text(operation.type == .copy ? "Copy" : "Move")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(operation.type == .copy ? Color.blue.opacity(0.2) : Color.orange.opacity(0.2))
                    )
                
                // Status text
                statusText
            }
            
            // Progress bar
            if operation.status == .inProgress {
                ProgressView(value: operation.progress)
                    .progressViewStyle(.linear)
            }
            
            // Error message
            if let error = operation.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(rowBackgroundColor)
        )
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch operation.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
        case .inProgress:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 16, height: 16)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    private var statusText: some View {
        switch operation.status {
        case .pending:
            Text("Waiting...")
                .font(.caption)
                .foregroundColor(.secondary)
        case .inProgress:
            Text("\(Int(operation.progress * 100))%")
                .font(.caption)
                .foregroundColor(.blue)
        case .completed:
            Text("Done")
                .font(.caption)
                .foregroundColor(.green)
        case .failed:
            Text("Failed")
                .font(.caption)
                .foregroundColor(.red)
        }
    }
    
    private var rowBackgroundColor: Color {
        switch operation.status {
        case .completed:
            return Color.green.opacity(0.1)
        case .failed:
            return Color.red.opacity(0.1)
        default:
            return Color(nsColor: .controlBackgroundColor)
        }
    }
}
