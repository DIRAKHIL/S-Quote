//
//  Quote.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import Foundation

struct Quote: Identifiable, Codable, Hashable {
    let id: UUID
    var event: Event
    var items: [QuoteItem]
    var discountPercentage: Double = 0.0
    var taxPercentage: Double = 8.5
    var additionalFees: Double = 0.0
    var notes: String = ""
    var validUntil: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    var status: QuoteStatus = .draft
    var createdDate: Date = Date()
    var lastModified: Date = Date()
    
    var subtotal: Double {
        return items.filter { $0.isSelected }.reduce(0) { $0 + $1.totalPrice }
    }
    
    var discountAmount: Double {
        return subtotal * (discountPercentage / 100)
    }
    
    var taxableAmount: Double {
        return subtotal - discountAmount + additionalFees
    }
    
    var taxAmount: Double {
        return taxableAmount * (taxPercentage / 100)
    }
    
    var totalAmount: Double {
        return taxableAmount + taxAmount
    }
    
    var quoteNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: createdDate)
        let shortId = String(id.uuidString.prefix(8)).uppercased()
        return "QT-\(dateString)-\(shortId)"
    }
    
    init(event: Event, items: [QuoteItem] = []) {
        self.id = UUID()
        self.event = event
        self.items = items
    }
}

enum QuoteStatus: String, CaseIterable, Codable {
    case draft = "Draft"
    case sent = "Sent"
    case approved = "Approved"
    case rejected = "Rejected"
    case expired = "Expired"
    
    var color: String {
        switch self {
        case .draft: return "gray"
        case .sent: return "blue"
        case .approved: return "green"
        case .rejected: return "red"
        case .expired: return "orange"
        }
    }
}