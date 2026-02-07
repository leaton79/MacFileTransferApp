//
//  DualPaneView.swift
//  MacFileTransferApp
//

import SwiftUI

/// Main dual-pane file browser layout
struct DualPaneView: View {
    @StateObject private var leftPane = FileBrowserViewModel()
    @StateObject private var rightPane = FileBrowserViewModel()
    
    var body: some View {
        HSplitView {
            // Left pane
            FileBrowserPane(viewModel: leftPane)
                .frame(minWidth: 300)
            
            // Right pane
            FileBrowserPane(viewModel: rightPane)
                .frame(minWidth: 300)
        }
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                // Copy left → right
                Button(action: { copyLeftToRight() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                        Text("Copy →")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .disabled(leftPane.selectedItems.isEmpty)
                .help("Copy selected files from left pane to right pane")
                .buttonStyle(.bordered)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                
                // Copy right → left
                Button(action: { copyRightToLeft() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.title3)
                        Text("← Copy")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .disabled(rightPane.selectedItems.isEmpty)
                .help("Copy selected files from right pane to left pane")
                .buttonStyle(.bordered)
                .keyboardShortcut("c", modifiers: [.command, .option])
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                // Move left → right
                Button(action: { moveLeftToRight() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.to.line.compact")
                            .font(.title3)
                        Text("Move →")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .disabled(leftPane.selectedItems.isEmpty)
                .help("Move selected files from left pane to right pane")
                .buttonStyle(.bordered)
                .keyboardShortcut("m", modifiers: [.command, .shift])
                
                // Move right → left
                Button(action: { moveRightToLeft() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.to.line.compact")
                            .font(.title3)
                        Text("← Move")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .disabled(rightPane.selectedItems.isEmpty)
                .help("Move selected files from right pane to left pane")
                .buttonStyle(.bordered)
                .keyboardShortcut("m", modifiers: [.command, .option])
            }
        }
    }
    
    // MARK: - Transfer Actions
    
    private func copyLeftToRight() {
        let items = Array(leftPane.selectedItems)
        TransferQueue.shared.queueMultiple(
            items: items,
            to: rightPane.currentURL,
            type: .copy
        )
        leftPane.clearSelection()
        
        // Refresh destination pane after copy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            rightPane.refresh()
        }
    }
    
    private func copyRightToLeft() {
        let items = Array(rightPane.selectedItems)
        TransferQueue.shared.queueMultiple(
            items: items,
            to: leftPane.currentURL,
            type: .copy
        )
        rightPane.clearSelection()
        
        // Refresh destination pane after copy
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            leftPane.refresh()
        }
    }
    
    private func moveLeftToRight() {
        let items = Array(leftPane.selectedItems)
        TransferQueue.shared.queueMultiple(
            items: items,
            to: rightPane.currentURL,
            type: .move
        )
        leftPane.clearSelection()
        
        // Refresh both panes after move
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            leftPane.refresh()
            rightPane.refresh()
        }
    }
    
    private func moveRightToLeft() {
        let items = Array(rightPane.selectedItems)
        TransferQueue.shared.queueMultiple(
            items: items,
            to: leftPane.currentURL,
            type: .move
        )
        rightPane.clearSelection()
        
        // Refresh both panes after move
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            rightPane.refresh()
            leftPane.refresh()
        }
    }
}
