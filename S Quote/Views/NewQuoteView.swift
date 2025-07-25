//
//  NewQuoteView.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import SwiftUI

struct NewQuoteView: View {
    let quoteService: QuoteService
    let onSave: (Quote) -> Void
    
    @StateObject private var viewModel: QuoteViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    private let steps = ["Event Details", "Select Items", "Pricing", "Review"]
    
    init(quoteService: QuoteService, onSave: @escaping (Quote) -> Void) {
        self.quoteService = quoteService
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: QuoteViewModel(quoteService: quoteService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                // Step Indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(index <= currentStep ? .white : .gray)
                                )
                            
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Step Labels
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Text(steps[index])
                            .font(.caption)
                            .fontWeight(index == currentStep ? .semibold : .regular)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Divider()
                
                // Step Content
                TabView(selection: $currentStep) {
                    EventDetailsStepView(viewModel: viewModel)
                        .tag(0)
                    
                    ItemSelectionStepView(viewModel: viewModel)
                        .tag(1)
                    
                    PricingStepView(viewModel: viewModel)
                        .tag(2)
                    
                    ReviewStepView(viewModel: viewModel)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Divider()
                
                // Navigation Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceedToNextStep)
                    } else {
                        Button("Save Quote") {
                            viewModel.saveQuote()
                            onSave(viewModel.currentQuote)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.isQuoteValid)
                    }
                }
                .padding()
            }
            .navigationTitle("New Quote")
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case 0: // Event Details
            return !viewModel.currentQuote.event.clientName.isEmpty &&
                   !viewModel.currentQuote.event.eventName.isEmpty &&
                   !viewModel.currentQuote.event.venue.isEmpty &&
                   viewModel.currentQuote.event.guestCount > 0
        case 1: // Item Selection
            return !viewModel.selectedItems.isEmpty
        case 2: // Pricing
            return true
        default:
            return true
        }
    }
}

// MARK: - Step Views

struct EventDetailsStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Event Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                // Client Information
                GroupBox("Client Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Client Name *")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter client name", text: $viewModel.currentQuote.event.clientName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("client@email.com", text: $viewModel.currentQuote.event.clientEmail)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Phone")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Phone number", text: $viewModel.currentQuote.event.clientPhone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding()
                }
                
                // Event Information
                GroupBox("Event Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Event Name *")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Enter event name", text: $viewModel.currentQuote.event.eventName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Event Type")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Picker("Event Type", selection: $viewModel.currentQuote.event.eventType) {
                                    ForEach(EventType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.rawValue)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Event Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $viewModel.currentQuote.event.eventDate, displayedComponents: [.date])
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Duration (hours)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("4.0", value: $viewModel.currentQuote.event.duration, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Venue *")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Enter venue name/address", text: $viewModel.currentQuote.event.venue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Guest Count *")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Number of guests", value: $viewModel.currentQuote.event.guestCount, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Special Requirements")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $viewModel.currentQuote.event.specialRequirements)
                                .frame(height: 80)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                }
                
                Text("* Required fields")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct ItemSelectionStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Items & Services")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Search and Filter
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search items...", text: $viewModel.searchText)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All Categories").tag(nil as ItemCategory?)
                        ForEach(ItemCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category as ItemCategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
            }
            .padding()
            
            Divider()
            
            // Items List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.filteredItems) { item in
                        ItemSelectionRow(item: item, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
    }
}

struct ItemSelectionRow: View {
    let item: QuoteItem
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        HStack {
            // Selection Checkbox
            Button(action: {
                viewModel.toggleItemSelection(item)
            }) {
                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isSelected ? .blue : .gray)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Category Icon
            Image(systemName: item.category.icon)
                .foregroundColor(Color(item.category.color))
                .frame(width: 20)
            
            // Item Details
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("\(item.unitPrice, format: .currency(code: "USD")) \(item.unit)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Quantity Controls
            if item.isSelected {
                HStack {
                    Button("-") {
                        viewModel.updateItemQuantity(item, quantity: item.quantity - 1)
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .frame(width: 30)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("+") {
                        viewModel.updateItemQuantity(item, quantity: item.quantity + 1)
                    }
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                
                Text(item.totalPrice, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding()
        .background(item.isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PricingStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pricing & Adjustments")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                // Selected Items Summary
                GroupBox("Selected Items") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.selectedItems) { item in
                            HStack {
                                Text(item.name)
                                Spacer()
                                Text("\(item.quantity) × \(item.unitPrice, format: .currency(code: "USD"))")
                                    .foregroundColor(.secondary)
                                Text(item.totalPrice, format: .currency(code: "USD"))
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Subtotal")
                                .fontWeight(.semibold)
                            Spacer()
                            Text(viewModel.currentQuote.subtotal, format: .currency(code: "USD"))
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                }
                
                // Adjustments
                GroupBox("Adjustments") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Discount (%)")
                            Spacer()
                            TextField("0.0", value: $viewModel.currentQuote.discountPercentage, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            Text("-\(viewModel.currentQuote.discountAmount, format: .currency(code: "USD"))")
                                .foregroundColor(.red)
                                .frame(width: 80, alignment: .trailing)
                        }
                        
                        HStack {
                            Text("Additional Fees")
                            Spacer()
                            TextField("0.00", value: $viewModel.currentQuote.additionalFees, format: .currency(code: "USD"))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                        }
                        
                        HStack {
                            Text("Tax (%)")
                            Spacer()
                            TextField("8.5", value: $viewModel.currentQuote.taxPercentage, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                            Text(viewModel.currentQuote.taxAmount, format: .currency(code: "USD"))
                                .foregroundColor(.blue)
                                .frame(width: 80, alignment: .trailing)
                        }
                    }
                    .padding()
                }
                
                // Total
                GroupBox {
                    HStack {
                        Text("TOTAL AMOUNT")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Text(viewModel.currentQuote.totalAmount, format: .currency(code: "USD"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                }
                
                // Quote Settings
                GroupBox("Quote Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Valid Until")
                            Spacer()
                            DatePicker("", selection: $viewModel.currentQuote.validUntil, displayedComponents: [.date])
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextEditor(text: $viewModel.currentQuote.notes)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
}

struct ReviewStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Review Quote")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom)
                
                // Validation Errors
                if !viewModel.validationErrors.isEmpty {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Please fix the following issues:")
                                    .fontWeight(.medium)
                            }
                            
                            ForEach(viewModel.validationErrors, id: \.self) { error in
                                Text("• \(error)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                    .background(Color.orange.opacity(0.1))
                }
                
                // Quote Preview
                GroupBox("Quote Preview") {
                    ScrollView {
                        Text(viewModel.exportQuote())
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(height: 400)
                    .background(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Export Options
                HStack {
                    Button("Copy to Clipboard") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(viewModel.exportQuote(), forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            .padding()
        }
    }
}

#Preview {
    NewQuoteView(quoteService: QuoteService()) { _ in }
}