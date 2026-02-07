//
//  ContentView.swift
//  MacFileTransferApp
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Main dual-pane file browser
            DualPaneView()
            
            // Transfer queue at bottom
            TransferStatusView()
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
