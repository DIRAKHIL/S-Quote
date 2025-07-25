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
                // Modern Header with Progress
                VStack(spacing: 20) {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(steps.count), height: 4)
                                .cornerRadius(2)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                    .frame(height: 4)
                    
                    // Step Indicators
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(stepBackgroundColor(for: index))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: index <= currentStep ? .blue.opacity(0.3) : .clear, radius: 6)
                                        .scaleEffect(index == currentStep ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                                    
                                    if index < currentStep {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(index + 1)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(stepTextColor(for: index))
                                    }
                                }
                                
                                Text(steps[index])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(index <= currentStep ? .primary : .secondary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: 80)
                            }
                            
                            if index < steps.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Current Step Title
                    VStack(spacing: 8) {
                        Text("Step \(currentStep + 1) of \(steps.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(steps[currentStep])
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 30)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemBackground),
                            Color(.systemGray6).opacity(0.5)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Content Area
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Group {
                            switch index {
                            case 0:
                                EventDetailsStepView(viewModel: viewModel)
                            case 1:
                                ItemSelectionStepView(viewModel: viewModel)
                            case 2:
                                PricingStepView(viewModel: viewModel)
                            case 3:
                                ReviewStepView(viewModel: viewModel)
                            default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(DefaultTabViewStyle())
                
                // Modern Navigation Footer
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 20) {
                        // Previous Button
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Previous")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.blue)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Spacer()
                                .frame(width: 100)
                        }
                        
                        Spacer()
                        
                        // Next/Create Button
                        if currentStep < steps.count - 1 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep += 1
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text("Next")
                                        .font(.system(size: 16, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    canProceedToNextStep ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray, Color.gray]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: canProceedToNextStep ? .blue.opacity(0.4) : .clear, radius: 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(!canProceedToNextStep)
                            .scaleEffect(canProceedToNextStep ? 1.0 : 0.95)
                            .animation(.easeInOut(duration: 0.2), value: canProceedToNextStep)
                        } else {
                            Button(action: {
                                viewModel.saveQuote()
                                onSave(viewModel.currentQuote)
                                dismiss()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Create Quote")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.4), radius: 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                            Text("Cancel")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("New Quote")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Event Planner")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func stepBackgroundColor(for index: Int) -> Color {
        if index < currentStep {
            return .green
        } else if index == currentStep {
            return .blue
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private func stepTextColor(for index: Int) -> Color {
        if index <= currentStep {
            return .white
        } else {
            return .gray
        }
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
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Event Information")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Tell us about your event to create a personalized quote")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Client Information Card
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        Text("Client Information")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(spacing: 16) {
                        // Client Name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Client Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Enter client's full name", text: $viewModel.currentQuote.event.clientName)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.currentQuote.event.clientName.isEmpty ? Color.red.opacity(0.5) : Color.blue.opacity(0.3),
                                            lineWidth: viewModel.currentQuote.event.clientName.isEmpty ? 2 : 1
                                        )
                                )
                        }
                        
                        HStack(spacing: 16) {
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("client@email.com", text: $viewModel.currentQuote.event.clientEmail)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            // Phone
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                TextField("+1 (555) 123-4567", text: $viewModel.currentQuote.event.clientPhone)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                // Event Details Card
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        Text("Event Details")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    
                    VStack(spacing: 16) {
                        // Event Name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Event Name")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("e.g., Sarah & John's Wedding Celebration", text: $viewModel.currentQuote.event.eventName)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.currentQuote.event.eventName.isEmpty ? Color.red.opacity(0.5) : Color.blue.opacity(0.3),
                                            lineWidth: viewModel.currentQuote.event.eventName.isEmpty ? 2 : 1
                                        )
                                )
                        }
                        
                        HStack(spacing: 16) {
                            // Event Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Type")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Picker("Event Type", selection: $viewModel.currentQuote.event.eventType) {
                                    Text("Wedding").tag("Wedding")
                                    Text("Corporate").tag("Corporate")
                                    Text("Birthday").tag("Birthday")
                                    Text("Anniversary").tag("Anniversary")
                                    Text("Other").tag("Other")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Event Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Event Date")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                DatePicker("", selection: $viewModel.currentQuote.event.eventDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Venue
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Venue")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("e.g., Grand Ballroom, 123 Main Street, City", text: $viewModel.currentQuote.event.venue)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.currentQuote.event.venue.isEmpty ? Color.red.opacity(0.5) : Color.blue.opacity(0.3),
                                            lineWidth: viewModel.currentQuote.event.venue.isEmpty ? 2 : 1
                                        )
                                )
                        }
                        
                        // Guest Count
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Expected Guests")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text("*")
                                    .foregroundColor(.red)
                            }
                            
                            TextField("Number of guests", value: $viewModel.currentQuote.event.guestCount, format: .number)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            viewModel.currentQuote.event.guestCount <= 0 ? Color.red.opacity(0.5) : Color.blue.opacity(0.3),
                                            lineWidth: viewModel.currentQuote.event.guestCount <= 0 ? 2 : 1
                                        )
                                )
                        }
                        
                        // Special Requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Special Requirements")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextEditor(text: $viewModel.currentQuote.event.specialRequirements)
                                .font(.system(size: 16))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(height: 100)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
}

struct ItemSelectionStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    Text("Select Services")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Choose the services you'd like to include in your quote")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Services Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.availableItems, id: \.id) { item in
                        ServiceCard(
                            item: item,
                            isSelected: viewModel.selectedItems.contains(where: { $0.id == item.id }),
                            onToggle: {
                                viewModel.toggleItemSelection(item)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
}

struct ServiceCard: View {
    let item: QuoteItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: iconForCategory(item.category))
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .blue)
                
                // Name
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Price
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .green)
                
                // Category
                Text(item.category)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(16)
            .frame(height: 160)
            .background(
                isSelected ? 
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground), Color(.systemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.05), radius: isSelected ? 8 : 4)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "catering":
            return "fork.knife.circle.fill"
        case "decoration":
            return "sparkles"
        case "entertainment":
            return "music.note"
        case "photography":
            return "camera.fill"
        case "videography":
            return "video.fill"
        case "flowers":
            return "leaf.fill"
        case "lighting":
            return "lightbulb.fill"
        case "sound":
            return "speaker.wave.3.fill"
        default:
            return "star.fill"
        }
    }
}

struct PricingStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Pricing Overview")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Review and adjust pricing for selected services")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Selected Items
                VStack(spacing: 16) {
                    ForEach(viewModel.selectedItems, id: \.id) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(item.category)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", item.price))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
                .padding(.horizontal, 20)
                
                // Total
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack {
                        Text("Total Amount")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", viewModel.totalAmount))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.2), radius: 8)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
}

struct ReviewStepView: View {
    @ObservedObject var viewModel: QuoteViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Review Quote")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Final review before creating your quote")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Event Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Event Summary")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        InfoRow(label: "Event", value: viewModel.currentQuote.event.eventName)
                        InfoRow(label: "Client", value: viewModel.currentQuote.event.clientName)
                        InfoRow(label: "Date", value: DateFormatter.localizedString(from: viewModel.currentQuote.event.eventDate, dateStyle: .medium, timeStyle: .none))
                        InfoRow(label: "Venue", value: viewModel.currentQuote.event.venue)
                        InfoRow(label: "Guests", value: "\(viewModel.currentQuote.event.guestCount)")
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8)
                .padding(.horizontal, 20)
                
                // Services Summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Selected Services")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.selectedItems, id: \.id) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", item.price))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", viewModel.totalAmount))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGray6).opacity(0.3))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}