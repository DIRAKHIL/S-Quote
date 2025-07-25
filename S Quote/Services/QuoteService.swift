//
//  QuoteService.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import Foundation

class QuoteService: ObservableObject {
    @Published var quotes: [Quote] = []
    @Published var defaultItems: [QuoteItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let quotesKey = "SavedQuotes"
    private let defaultItemsKey = "DefaultItems"
    
    init() {
        loadQuotes()
        loadDefaultItems()
        if defaultItems.isEmpty {
            createDefaultItems()
        }
    }
    
    // MARK: - Quote Management
    func addQuote(_ quote: Quote) {
        quotes.append(quote)
        saveQuotes()
    }
    
    func updateQuote(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            var updatedQuote = quote
            updatedQuote.lastModified = Date()
            quotes[index] = updatedQuote
            saveQuotes()
        }
    }
    
    func deleteQuote(_ quote: Quote) {
        quotes.removeAll { $0.id == quote.id }
        saveQuotes()
    }
    
    // MARK: - Default Items Management
    func addDefaultItem(_ item: QuoteItem) {
        defaultItems.append(item)
        saveDefaultItems()
    }
    
    func updateDefaultItem(_ item: QuoteItem) {
        if let index = defaultItems.firstIndex(where: { $0.id == item.id }) {
            defaultItems[index] = item
            saveDefaultItems()
        }
    }
    
    func deleteDefaultItem(_ item: QuoteItem) {
        defaultItems.removeAll { $0.id == item.id }
        saveDefaultItems()
    }
    
    // MARK: - Persistence
    private func saveQuotes() {
        if let encoded = try? JSONEncoder().encode(quotes) {
            userDefaults.set(encoded, forKey: quotesKey)
        }
    }
    
    private func loadQuotes() {
        if let data = userDefaults.data(forKey: quotesKey),
           let decoded = try? JSONDecoder().decode([Quote].self, from: data) {
            quotes = decoded
        }
    }
    
    private func saveDefaultItems() {
        if let encoded = try? JSONEncoder().encode(defaultItems) {
            userDefaults.set(encoded, forKey: defaultItemsKey)
        }
    }
    
    private func loadDefaultItems() {
        if let data = userDefaults.data(forKey: defaultItemsKey),
           let decoded = try? JSONDecoder().decode([QuoteItem].self, from: data) {
            defaultItems = decoded
        }
    }
    
    // MARK: - Default Items Creation
    private func createDefaultItems() {
        defaultItems = [
            // Photography - Based on Ashok's wedding quote
            QuoteItem(name: "Traditional Still Camera", description: "Professional traditional photography for all events", category: .photography, unitPrice: 15000.0, quantity: 1, unit: "per event"),
            QuoteItem(name: "Candid Photography", description: "Candid photography with professional equipment", category: .photography, unitPrice: 20000.0, quantity: 1, unit: "per event"),
            QuoteItem(name: "4K Video", description: "4K video recording for all ceremonies", category: .photography, unitPrice: 25000.0, quantity: 1, unit: "per event"),
            QuoteItem(name: "Cinematic Video", description: "Cinematic video with Sony HD cameras", category: .photography, unitPrice: 30000.0, quantity: 1, unit: "per event"),
            QuoteItem(name: "Drone Photography", description: "Aerial photography and videography", category: .photography, unitPrice: 15000.0, quantity: 1, unit: "per event"),
            QuoteItem(name: "Wedding Albums", description: "100 sheets premium glossy albums for bride & groom", category: .photography, unitPrice: 8000.0, quantity: 2, unit: "per album"),
            QuoteItem(name: "Pre/Post Wedding Shoot", description: "Complimentary couple shoot", category: .photography, unitPrice: 0.0, quantity: 1, unit: "complimentary"),
            QuoteItem(name: "Event Promos", description: "Short promotional videos for each event", category: .photography, unitPrice: 5000.0, quantity: 1, unit: "per event"),
            
            // Equipment - Professional Photography Equipment
            QuoteItem(name: "LED Screens", description: "LED screens for live display", category: .equipment, unitPrice: 8000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Professional Lighting", description: "Studio lighting setup", category: .equipment, unitPrice: 5000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Sound System", description: "Professional sound system", category: .equipment, unitPrice: 3000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Camera Equipment", description: "Nikon Z8, Sony S3, Sony FX3 with lenses", category: .equipment, unitPrice: 12000.0, quantity: 1, unit: "per day"),
            
            // Catering
            QuoteItem(name: "Wedding Dinner", description: "3-course dinner per person", category: .catering, unitPrice: 850.0, quantity: 1, unit: "per person"),
            QuoteItem(name: "Cocktail Hour", description: "Open bar and appetizers", category: .catering, unitPrice: 250.0, quantity: 1, unit: "per person"),
            QuoteItem(name: "Wedding Cake", description: "Custom wedding cake", category: .catering, unitPrice: 4500.0, quantity: 1, unit: "per cake"),
            QuoteItem(name: "Breakfast/Lunch", description: "Traditional breakfast or lunch", category: .catering, unitPrice: 400.0, quantity: 1, unit: "per person"),
            
            // Decoration
            QuoteItem(name: "Mandap Decoration", description: "Traditional wedding mandap decoration", category: .decoration, unitPrice: 25000.0, quantity: 1, unit: "per setup"),
            QuoteItem(name: "Stage Decoration", description: "Reception stage decoration", category: .decoration, unitPrice: 15000.0, quantity: 1, unit: "per setup"),
            QuoteItem(name: "Entrance Decoration", description: "Grand entrance decoration", category: .decoration, unitPrice: 8000.0, quantity: 1, unit: "per setup"),
            QuoteItem(name: "Table Centerpieces", description: "Floral centerpieces for tables", category: .decoration, unitPrice: 750.0, quantity: 1, unit: "per table"),
            QuoteItem(name: "Lighting Decoration", description: "Ambient and decorative lighting", category: .decoration, unitPrice: 12000.0, quantity: 1, unit: "per setup"),
            
            // Entertainment
            QuoteItem(name: "DJ Services", description: "Professional DJ with sound system", category: .entertainment, unitPrice: 8000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Live Band", description: "Traditional/modern live band", category: .entertainment, unitPrice: 15000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Dhol Players", description: "Traditional dhol players", category: .entertainment, unitPrice: 3000.0, quantity: 2, unit: "per player"),
            QuoteItem(name: "Dance Performers", description: "Professional dance performers", category: .entertainment, unitPrice: 10000.0, quantity: 1, unit: "per performance"),
            
            // Venue
            QuoteItem(name: "Wedding Hall", description: "Air-conditioned wedding hall", category: .venue, unitPrice: 50000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Outdoor Venue", description: "Garden/outdoor ceremony space", category: .venue, unitPrice: 30000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Parking Space", description: "Dedicated parking area", category: .venue, unitPrice: 5000.0, quantity: 1, unit: "per day"),
            
            // Staffing
            QuoteItem(name: "Event Coordinator", description: "Professional wedding coordinator", category: .staffing, unitPrice: 1500.0, quantity: 8, unit: "per hour"),
            QuoteItem(name: "Waitstaff", description: "Professional serving staff", category: .staffing, unitPrice: 250.0, quantity: 1, unit: "per hour per person"),
            QuoteItem(name: "Security Staff", description: "Event security personnel", category: .staffing, unitPrice: 300.0, quantity: 8, unit: "per hour"),
            QuoteItem(name: "Makeup Artist", description: "Professional makeup artist", category: .staffing, unitPrice: 8000.0, quantity: 1, unit: "per day"),
            
            // Transportation
            QuoteItem(name: "Bridal Car", description: "Decorated luxury car for bride", category: .transportation, unitPrice: 5000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Guest Transportation", description: "Bus/van for guest transportation", category: .transportation, unitPrice: 8000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Horse/Elephant", description: "Traditional groom entry", category: .transportation, unitPrice: 12000.0, quantity: 1, unit: "per day"),
            
            // Flowers
            QuoteItem(name: "Bridal Bouquet", description: "Custom bridal bouquet", category: .flowers, unitPrice: 1500.0, quantity: 1, unit: "per bouquet"),
            QuoteItem(name: "Garlands", description: "Fresh flower garlands", category: .flowers, unitPrice: 500.0, quantity: 10, unit: "per garland"),
            QuoteItem(name: "Flower Petals", description: "Rose petals for ceremony", category: .flowers, unitPrice: 800.0, quantity: 5, unit: "per kg"),
            QuoteItem(name: "Floral Jewelry", description: "Traditional floral jewelry", category: .flowers, unitPrice: 2000.0, quantity: 1, unit: "per set"),
            
            // Other Services
            QuoteItem(name: "Invitation Cards", description: "Custom wedding invitation design & printing", category: .other, unitPrice: 50.0, quantity: 200, unit: "per card"),
            QuoteItem(name: "Mehendi Artist", description: "Professional mehendi/henna artist", category: .other, unitPrice: 5000.0, quantity: 1, unit: "per day"),
            QuoteItem(name: "Pandit/Priest", description: "Wedding ceremony priest", category: .other, unitPrice: 3000.0, quantity: 1, unit: "per ceremony"),
            QuoteItem(name: "Return Gifts", description: "Wedding return gifts for guests", category: .other, unitPrice: 200.0, quantity: 1, unit: "per gift")
        ]
        saveDefaultItems()
    }
    
    // MARK: - Export Functions
    func generateQuoteText(_ quote: Quote) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        
        var text = """
        EVENT QUOTATION
        ================
        
        Quote Number: \(quote.quoteNumber)
        Date: \(formatter.string(from: quote.createdDate))
        Valid Until: \(formatter.string(from: quote.validUntil))
        
        CLIENT INFORMATION
        ------------------
        Name: \(quote.event.clientName)
        Email: \(quote.event.clientEmail)
        Phone: \(quote.event.clientPhone)
        
        EVENT DETAILS
        -------------
        Event: \(quote.event.eventName)
        Type: \(quote.event.eventType.rawValue)
        Date: \(formatter.string(from: quote.event.eventDate))
        Venue: \(quote.event.venue)
        Guests: \(quote.event.guestCount)
        Duration: \(quote.event.duration) hours
        
        """
        
        if !quote.event.specialRequirements.isEmpty {
            text += "Special Requirements: \(quote.event.specialRequirements)\n\n"
        }
        
        text += "QUOTATION BREAKDOWN\n"
        text += "-------------------\n\n"
        
        let selectedItems = quote.items.filter { $0.isSelected }
        let groupedItems = Dictionary(grouping: selectedItems) { $0.category }
        
        for category in ItemCategory.allCases {
            if let items = groupedItems[category], !items.isEmpty {
                text += "\(category.rawValue.uppercased())\n"
                for item in items {
                    let total = currencyFormatter.string(from: NSNumber(value: item.totalPrice)) ?? "$0.00"
                    text += "• \(item.name) - \(item.quantity) \(item.unit) @ \(currencyFormatter.string(from: NSNumber(value: item.unitPrice)) ?? "$0.00") = \(total)\n"
                    if !item.description.isEmpty {
                        text += "  \(item.description)\n"
                    }
                }
                text += "\n"
            }
        }
        
        text += "PRICING SUMMARY\n"
        text += "---------------\n"
        text += "Subtotal: \(currencyFormatter.string(from: NSNumber(value: quote.subtotal)) ?? "$0.00")\n"
        
        if quote.discountPercentage > 0 {
            text += "Discount (\(String(format: "%.1f", quote.discountPercentage))%): -\(currencyFormatter.string(from: NSNumber(value: quote.discountAmount)) ?? "$0.00")\n"
        }
        
        if quote.additionalFees > 0 {
            text += "Additional Fees: \(currencyFormatter.string(from: NSNumber(value: quote.additionalFees)) ?? "$0.00")\n"
        }
        
        text += "Tax (\(String(format: "%.1f", quote.taxPercentage))%): \(currencyFormatter.string(from: NSNumber(value: quote.taxAmount)) ?? "$0.00")\n"
        text += "TOTAL: \(currencyFormatter.string(from: NSNumber(value: quote.totalAmount)) ?? "$0.00")\n\n"
        
        if !quote.notes.isEmpty {
            text += "NOTES\n"
            text += "-----\n"
            text += "\(quote.notes)\n\n"
        }
        
        text += "Thank you for considering our services for your special event!\n"
        
        return text
    }
}