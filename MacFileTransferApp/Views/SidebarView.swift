//
//  SidebarView.swift
//  MacFileTransferApp
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    
    @State private var commonLocations: [FileItem] = []
    @State private var volumes: [FileItem] = []
    
    var body: some View {
        List {
            Section("Favorites") {
                ForEach(commonLocations) { location in
                    Button(action: {
                        viewModel.navigate(to: location.url)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: location.iconName)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text(location.name)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section("Devices") {
                ForEach(volumes) { volume in
                    Button(action: {
                        viewModel.navigate(to: volume.url)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text(volume.name)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if volumes.isEmpty {
                    Text("No external drives")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200)
        .onAppear {
            loadLocations()
            loadVolumes()
        }
        .onChange(of: volumes.count) { oldValue, newValue in
            // Refresh when drives are mounted/unmounted
        }
    }
    
    private func loadLocations() {
        let fileService = FileSystemService.shared
        commonLocations = fileService.getCommonLocations()
    }
    
    private func loadVolumes() {
        let fileService = FileSystemService.shared
        volumes = fileService.getVolumes().filter { volume in
            // Filter out the main system volume
            !volume.url.path.hasPrefix("/System/Volumes")
        }
    }
}
