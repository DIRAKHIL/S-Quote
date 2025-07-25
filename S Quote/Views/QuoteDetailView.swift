//
//  QuoteDetailView.swift
//  S Quote
//
//  Created by OpenHands on 25/07/25.
//

import SwiftUI

struct QuoteDetailView: View {
    let quote: Quote
    let quoteService: QuoteService
    
    @StateObject private var viewModel: QuoteViewModel
    @State private var showingEditSheet = false
    @State private var showingExportSheet = false
    @State private var exportText = ""
    
    init(quote: Quote, quoteService: QuoteService) {
        self.quote = quote
        self.quoteService = quoteService
        self._viewModel = StateObject(wrappedValue: QuoteViewModel(quote: quote, quoteService: quoteService))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                // Event Details
                eventDetailsSection
                
                // Selected Items
                selectedItemsSection
                
                // Pricing Summary
                pricingSummarySection
                
                // Notes
                if !viewModel.currentQuote.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.currentQuote.event.eventName.isEmpty ? "Untitled Event" : viewModel.currentQuote.event.eventName)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Export") {
                    exportText = viewModel.exportQuote()
                    showingExportSheet = true
                }
                .buttonStyle(.bordered)
                
                Button("Edit") {
                    showingEditSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditQuoteView(quote: viewModel.currentQuote, quoteService: quoteService) { updatedQuote in
                viewModel.currentQuote = updatedQuote
                showingEditSheet = false
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportQuoteView(quoteText: exportText, quote: viewModel.currentQuote)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.currentQuote.quoteNumber)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Created: \(viewModel.currentQuote.createdDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    StatusBadge(status: viewModel.currentQuote.status)
                    
                    Text("Valid until: \(viewModel.currentQuote.validUntil, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(viewModel.currentQuote.totalAmount, format: .currency(code: "USD"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: viewModel.currentQuote.event.eventType.icon)
                    Text(viewModel.currentQuote.event.eventType.rawValue)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var eventDetailsSection: some View {
        GroupBox("Event Details") {
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Client", value: viewModel.currentQuote.event.clientName)
                
                if !viewModel.currentQuote.event.clientEmail.isEmpty {
                    DetailRow(label: "Email", value: viewModel.currentQuote.event.clientEmail)
                }
                
                if !viewModel.currentQuote.event.clientPhone.isEmpty {
                    DetailRow(label: "Phone", value: viewModel.currentQuote.event.clientPhone)
                }
                
                Divider()
                
                DetailRow(label: "Event Date", value: viewModel.currentQuote.event.eventDate.formatted(date: .complete, time: .omitted))
                DetailRow(label: "Venue", value: viewModel.currentQuote.event.venue)
                DetailRow(label: "Guests", value: "\(viewModel.currentQuote.event.guestCount)")
                DetailRow(label: "Duration", value: String(format: "%.1f hours", viewModel.currentQuote.event.duration))
                
                if !viewModel.currentQuote.event.specialRequirements.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Special Requirements")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(viewModel.currentQuote.event.specialRequirements)
                            .font(.body)
                    }
                }
            }
            .padding()
        }
    }
    
    private var selectedItemsSection: some View {
        GroupBox("Selected Items & Services") {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(ItemCategory.allCases, id: \.self) { category in
                    let categoryItems = viewModel.selectedItems.filter { $0.category == category }
                    
                    if !categoryItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(category.color))
                                Text(category.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            
                            ForEach(categoryItems) { item in
                                ItemDetailRow(item: item)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding()
        }
    }
    
    private var pricingSummarySection: some View {
        GroupBox("Pricing Summary") {
            VStack(spacing: 8) {
                PricingRow(label: "Subtotal", amount: viewModel.currentQuote.subtotal)
                
                if viewModel.currentQuote.discountPercentage > 0 {
                    PricingRow(
                        label: "Discount (\(String(format: "%.1f", viewModel.currentQuote.discountPercentage))%)",
                        amount: -viewModel.currentQuote.discountAmount,
                        color: .red
                    )
                }
                
                if viewModel.currentQuote.additionalFees > 0 {
                    PricingRow(label: "Additional Fees", amount: viewModel.currentQuote.additionalFees)
                }
                
                PricingRow(
                    label: "Tax (\(String(format: "%.1f", viewModel.currentQuote.taxPercentage))%)",
                    amount: viewModel.currentQuote.taxAmount,
                    color: .blue
                )
                
                Divider()
                
                HStack {
                    Text("TOTAL")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text(viewModel.currentQuote.totalAmount, format: .currency(code: "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
    
    private var notesSection: some View {
        GroupBox("Notes") {
            Text(viewModel.currentQuote.notes)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.body)
            
            Spacer()
        }
    }
}

struct ItemDetailRow: View {
    let item: QuoteItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(item.quantity) × \(item.unitPrice, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.totalPrice, format: .currency(code: "USD"))
                    .font(.body)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PricingRow: View {
    let label: String
    let amount: Double
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            Text(amount, format: .currency(code: "USD"))
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct EditQuoteView: View {
    let quote: Quote
    let quoteService: QuoteService
    let onSave: (Quote) -> Void
    
    @StateObject private var viewModel: QuoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(quote: Quote, quoteService: QuoteService, onSave: @escaping (Quote) -> Void) {
        self.quote = quote
        self.quoteService = quoteService
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: QuoteViewModel(quote: quote, quoteService: quoteService))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Client Name", text: $viewModel.currentQuote.event.clientName)
                    TextField("Event Name", text: $viewModel.currentQuote.event.eventName)
                    TextField("Venue", text: $viewModel.currentQuote.event.venue)
                    
                    HStack {
                        Text("Guests")
                        Spacer()
                        TextField("Count", value: $viewModel.currentQuote.event.guestCount, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    DatePicker("Event Date", selection: $viewModel.currentQuote.event.eventDate, displayedComponents: [.date])
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Discount (%)")
                        Spacer()
                        TextField("0.0", value: $viewModel.currentQuote.discountPercentage, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Tax (%)")
                        Spacer()
                        TextField("8.5", value: $viewModel.currentQuote.taxPercentage, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Additional Fees")
                        Spacer()
                        TextField("0.00", value: $viewModel.currentQuote.additionalFees, format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                }
                
                Section("Status & Validity") {
                    Picker("Status", selection: $viewModel.currentQuote.status) {
                        ForEach(QuoteStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    
                    DatePicker("Valid Until", selection: $viewModel.currentQuote.validUntil, displayedComponents: [.date])
                }
                
                Section("Notes") {
                    TextEditor(text: $viewModel.currentQuote.notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Edit Quote")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveQuote()
                        onSave(viewModel.currentQuote)
                    }
                    .disabled(!viewModel.isQuoteValid)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct ExportQuoteView: View {
    let quoteText: String
    let quote: Quote
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Quote")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ScrollView {
                    Text(quoteText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                HStack(spacing: 12) {
                    Button("Copy to Clipboard") {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(quoteText, forType: .string)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save as Text File") {
                        saveToFile()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 500)
    }
    
    private func saveToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "\(quote.quoteNumber).txt"
        
        if savePanel.runModal() == .OK {
            if let url = savePanel.url {
                try? quoteText.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

#Preview {
    let sampleQuote: Quote = {
        var event = Event()
        event.clientName = "John & Jane Doe"
        event.clientEmail = "john.doe@email.com"
        event.eventName = "Wedding Reception"
        event.eventType = .wedding
        event.venue = "Grand Ballroom"
        event.guestCount = 150
        
        return Quote(event: event, items: [])
    }()
    
    QuoteDetailView(quote: sampleQuote, quoteService: QuoteService())
}