//
//  Event.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import Foundation

struct Event: Identifiable, Codable {
    let id = UUID()
    var clientName: String = ""
    var clientEmail: String = ""
    var clientPhone: String = ""
    var eventName: String = ""
    var eventType: EventType = .wedding
    var eventDate: Date = Date()
    var venue: String = ""
    var guestCount: Int = 0
    var duration: Double = 4.0 // hours
    var specialRequirements: String = ""
    var createdDate: Date = Date()
}

enum EventType: String, CaseIterable, Codable {
    case wedding = "Wedding"
    case corporate = "Corporate Event"
    case birthday = "Birthday Party"
    case anniversary = "Anniversary"
    case conference = "Conference"
    case workshop = "Workshop"
    case graduation = "Graduation"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .wedding: return "heart.fill"
        case .corporate: return "building.2.fill"
        case .birthday: return "gift.fill"
        case .anniversary: return "calendar.badge.clock"
        case .conference: return "person.3.fill"
        case .workshop: return "hammer.fill"
        case .graduation: return "graduationcap.fill"
        case .other: return "star.fill"
        }
    }
}