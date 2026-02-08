//
//  SidebarView.swift
//  MacFileTransferApp
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: FileBrowserViewModel
    @ObservedObject var mtpService: MTPService
    
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
            
            // ── NEW: Android Devices Section ──
            Section("Android Devices") {
                if mtpService.isScanning {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Scanning…")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                ForEach(mtpService.detectedDevices) { device in
                                    Button(action: {
                                        viewModel.connectToMTPDevice(device, service: mtpService)
                                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apps.iphone")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.displayName)
                                    .foregroundColor(.primary)
                                if let storage = device.storageInfo.first {
                                    Text("\(storage.freeFormatted) free")
                                        .foregroundColor(.secondary)
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                if !mtpService.isScanning && mtpService.detectedDevices.isEmpty {
                    Text("No Android devices")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                // Rescan button
                Button(action: {
                    mtpService.scanForDevices()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                        Text("Scan for Devices")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            // ── END: Android Devices Section ──
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 200)
        .onAppear {
            loadLocations()
            loadVolumes()
            mtpService.scanForDevices()
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
            !volume.url.path.hasPrefix("/System/Volumes")
        }
    }
}
