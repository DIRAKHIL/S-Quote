//
//  QuoteViewModel.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import Foundation
import SwiftUI

class QuoteViewModel: ObservableObject {
    @Published var currentQuote: Quote
    @Published var availableItems: [QuoteItem] = []
    @Published var selectedCategory: ItemCategory? = nil
    @Published var searchText: String = ""
    
    private let quoteService: QuoteService
    
    init(quote: Quote? = nil, quoteService: QuoteService) {
        self.quoteService = quoteService
        self.currentQuote = quote ?? Quote(
            event: Event(),
            items: []
        )
        self.availableItems = quoteService.defaultItems.map { item in
            var newItem = item
            newItem.isSelected = false
            newItem.quantity = 1
            return newItem
        }
        
        // If editing existing quote, mark selected items
        if let existingQuote = quote {
            updateSelectedItems()
        }
    }
    
    // MARK: - Item Management
    func toggleItemSelection(_ item: QuoteItem) {
        if let index = availableItems.firstIndex(where: { $0.id == item.id }) {
            availableItems[index].isSelected.toggle()
            
            if availableItems[index].isSelected {
                // Add to quote
                if !currentQuote.items.contains(where: { $0.id == item.id }) {
                    currentQuote.items.append(availableItems[index])
                }
            } else {
                // Remove from quote
                currentQuote.items.removeAll { $0.id == item.id }
            }
            updateQuote()
        }
    }
    
    func updateItemQuantity(_ item: QuoteItem, quantity: Int) {
        // Update in available items
        if let availableIndex = availableItems.firstIndex(where: { $0.id == item.id }) {
            availableItems[availableIndex].quantity = max(1, quantity)
        }
        
        // Update in current quote items
        if let quoteIndex = currentQuote.items.firstIndex(where: { $0.id == item.id }) {
            currentQuote.items[quoteIndex].quantity = max(1, quantity)
        }
        
        updateQuote()
    }
    
    func addCustomItem(_ item: QuoteItem) {
        var newItem = item
        newItem.isSelected = true
        availableItems.append(newItem)
        currentQuote.items.append(newItem)
        updateQuote()
    }
    
    func removeItem(_ item: QuoteItem) {
        availableItems.removeAll { $0.id == item.id }
        currentQuote.items.removeAll { $0.id == item.id }
        updateQuote()
    }
    
    // MARK: - Filtering
    var filteredItems: [QuoteItem] {
        var items = availableItems
        
        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return items.sorted { $0.name < $1.name }
    }
    
    var selectedItems: [QuoteItem] {
        return currentQuote.items.filter { $0.isSelected }
    }
    
    var itemsByCategory: [ItemCategory: [QuoteItem]] {
        return Dictionary(grouping: selectedItems) { $0.category }
    }
    
    // MARK: - Quote Management
    func saveQuote() {
        currentQuote.lastModified = Date()
        
        if quoteService.quotes.contains(where: { $0.id == currentQuote.id }) {
            quoteService.updateQuote(currentQuote)
        } else {
            quoteService.addQuote(currentQuote)
        }
    }
    
    func updateQuote() {
        currentQuote.lastModified = Date()
        objectWillChange.send()
    }
    
    func updateEvent(_ event: Event) {
        currentQuote.event = event
        updateQuote()
    }
    
    func updateDiscount(_ percentage: Double) {
        currentQuote.discountPercentage = max(0, min(100, percentage))
        updateQuote()
    }
    
    func updateTax(_ percentage: Double) {
        currentQuote.taxPercentage = max(0, percentage)
        updateQuote()
    }
    
    func updateAdditionalFees(_ amount: Double) {
        currentQuote.additionalFees = max(0, amount)
        updateQuote()
    }
    
    func updateNotes(_ notes: String) {
        currentQuote.notes = notes
        updateQuote()
    }
    
    func updateValidUntil(_ date: Date) {
        currentQuote.validUntil = date
        updateQuote()
    }
    
    func updateStatus(_ status: QuoteStatus) {
        currentQuote.status = status
        updateQuote()
    }
    
    // MARK: - Export
    func exportQuote() -> String {
        return quoteService.generateQuoteText(currentQuote)
    }
    
    // MARK: - Private Methods
    private func updateSelectedItems() {
        let selectedItemIds = Set(currentQuote.items.map { $0.id })
        
        for index in availableItems.indices {
            availableItems[index].isSelected = selectedItemIds.contains(availableItems[index].id)
            
            // Update quantities from existing quote
            if let existingItem = currentQuote.items.first(where: { $0.id == availableItems[index].id }) {
                availableItems[index].quantity = existingItem.quantity
            }
        }
    }
    
    // MARK: - Validation
    var isQuoteValid: Bool {
        return !currentQuote.event.clientName.isEmpty &&
               !currentQuote.event.eventName.isEmpty &&
               !currentQuote.event.venue.isEmpty &&
               currentQuote.event.guestCount > 0 &&
               !selectedItems.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if currentQuote.event.clientName.isEmpty {
            errors.append("Client name is required")
        }
        
        if currentQuote.event.eventName.isEmpty {
            errors.append("Event name is required")
        }
        
        if currentQuote.event.venue.isEmpty {
            errors.append("Venue is required")
        }
        
        if currentQuote.event.guestCount <= 0 {
            errors.append("Guest count must be greater than 0")
        }
        
        if selectedItems.isEmpty {
            errors.append("At least one item must be selected")
        }
        
        return errors
    }
}