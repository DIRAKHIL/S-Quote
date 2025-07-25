//
//  ContentView.swift
//  S Quote
//
//  Created by Akhil Maddali on 25/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var quoteService = QuoteService()
    @State private var selectedQuote: Quote?
    @State private var showingNewQuote = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Quote List
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("S-Quote")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: { showingNewQuote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search quotes...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Quote List
                List(filteredQuotes, id: \.id, selection: $selectedQuote) { quote in
                    QuoteRowView(quote: quote)
                        .tag(quote)
                }
                .listStyle(SidebarListStyle())
            }
            .frame(minWidth: 300)
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
        } detail: {
            // Detail View
            if let selectedQuote = selectedQuote {
                QuoteDetailView(quote: selectedQuote, quoteService: quoteService)
            } else {
                // Welcome View
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Event Planner Quotation Generator")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Select a quote from the sidebar or create a new one to get started")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Create New Quote") {
                        showingNewQuote = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .sheet(isPresented: $showingNewQuote) {
            NewQuoteView(quoteService: quoteService) { newQuote in
                selectedQuote = newQuote
                showingNewQuote = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Quote") {
                    showingNewQuote = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
    
    private var filteredQuotes: [Quote] {
        if searchText.isEmpty {
            return quoteService.quotes.sorted { $0.createdDate > $1.createdDate }
        } else {
            return quoteService.quotes.filter { quote in
                quote.event.clientName.localizedCaseInsensitiveContains(searchText) ||
                quote.event.eventName.localizedCaseInsensitiveContains(searchText) ||
                quote.quoteNumber.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.createdDate > $1.createdDate }
        }
    }
}

struct QuoteRowView: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(quote.event.eventName.isEmpty ? "Untitled Event" : quote.event.eventName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                StatusBadge(status: quote.status)
            }
            
            Text(quote.event.clientName.isEmpty ? "No client" : quote.event.clientName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text(quote.quoteNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(quote.totalAmount, format: .currency(code: "USD"))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Text(quote.event.eventDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: QuoteStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(status.color).opacity(0.2))
            .foregroundColor(Color(status.color))
            .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
