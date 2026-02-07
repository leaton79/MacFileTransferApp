//
//  ColumnConfiguration.swift
//  MacFileTransferApp
//

import Foundation
import Combine

enum DetailColumn: String, CaseIterable, Identifiable {
    case name = "Name"
    case size = "Size"
    case type = "Type"
    case kind = "Kind"
    case dateModified = "Date Modified"
    case dateCreated = "Date Created"
    case dateAccessed = "Date Accessed"
    case permissions = "Permissions"
    case owner = "Owner"
    
    var id: String { rawValue }
    
    var width: ColumnWidth {
        switch self {
        case .name:
            return ColumnWidth(min: 200, ideal: 300, max: .infinity)
        case .size:
            return ColumnWidth(min: 80, ideal: 100, max: 150)
        case .type, .kind:
            return ColumnWidth(min: 100, ideal: 150, max: 200)
        case .dateModified, .dateCreated, .dateAccessed:
            return ColumnWidth(min: 150, ideal: 180, max: 250)
        case .permissions:
            return ColumnWidth(min: 80, ideal: 100, max: 120)
        case .owner:
            return ColumnWidth(min: 80, ideal: 120, max: 150)
        }
    }
}

struct ColumnWidth {
    let min: CGFloat
    let ideal: CGFloat
    let max: CGFloat?
}

class ColumnConfiguration: ObservableObject {
    @Published var visibleColumns: Set<DetailColumn>
    
    static let defaultColumns: Set<DetailColumn> = [
        .name, .size, .type, .dateModified
    ]
    
    init(visibleColumns: Set<DetailColumn> = defaultColumns) {
        self.visibleColumns = visibleColumns
    }
    
    func isVisible(_ column: DetailColumn) -> Bool {
        visibleColumns.contains(column)
    }
    
    func toggle(_ column: DetailColumn) {
        if column == .name {
            return // Name column is always visible
        }
        
        if visibleColumns.contains(column) {
            visibleColumns.remove(column)
        } else {
            visibleColumns.insert(column)
        }
    }
}
