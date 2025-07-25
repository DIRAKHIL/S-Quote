//
//  QuoteItem.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import Foundation

struct QuoteItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var category: ItemCategory
    var unitPrice: Double
    var quantity: Int
    var unit: String // e.g., "per hour", "per piece", "per person"
    var isSelected: Bool = false
    
    var totalPrice: Double {
        return unitPrice * Double(quantity)
    }
    
    init(name: String, description: String, category: ItemCategory, unitPrice: Double, quantity: Int = 1, unit: String) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.unit = unit
    }
}

enum ItemCategory: String, CaseIterable, Codable {
    case catering = "Catering"
    case decoration = "Decoration"
    case entertainment = "Entertainment"
    case photography = "Photography"
    case venue = "Venue"
    case transportation = "Transportation"
    case equipment = "Equipment"
    case staffing = "Staffing"
    case flowers = "Flowers"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .catering: return "fork.knife"
        case .decoration: return "paintbrush.fill"
        case .entertainment: return "music.note"
        case .photography: return "camera.fill"
        case .venue: return "building.columns.fill"
        case .transportation: return "car.fill"
        case .equipment: return "speaker.wave.3.fill"
        case .staffing: return "person.2.fill"
        case .flowers: return "leaf.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .catering: return "orange"
        case .decoration: return "purple"
        case .entertainment: return "blue"
        case .photography: return "green"
        case .venue: return "red"
        case .transportation: return "yellow"
        case .equipment: return "gray"
        case .staffing: return "pink"
        case .flowers: return "mint"
        case .other: return "brown"
        }
    }
}