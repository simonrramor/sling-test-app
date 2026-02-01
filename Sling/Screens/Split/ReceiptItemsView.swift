import SwiftUI
import UIKit

struct ReceiptItemsView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var themeService = ThemeService.shared
    @State var receipt: ScannedReceipt
    let onDismissAll: () -> Void
    
    @State private var showContactPicker = false
    @State private var selectedItemIndex: Int?
    @State private var showSummary = false
    
    // Sample contacts - reusing from SplitBillView
    let contacts: [Contact] = [
        Contact(name: "Agustin Alvarez", username: "@Agustine", avatarName: "AvatarAgustinAlvarez"),
        Contact(name: "Barry Donbeck", username: "@barry123", avatarName: "AvatarBarryDonbeck"),
        Contact(name: "Ben Johnson", username: "@benj", avatarName: "AvatarBenJohnson"),
        Contact(name: "Brendon Arnold", username: "@brendon", avatarName: "AvatarBrendonArnold"),
        Contact(name: "Carl Pattersmith", username: "@carlp", avatarName: "AvatarCarlPattersmith"),
        Contact(name: "Eileen Farrell", username: "@eileenf", avatarName: "AvatarEileenFarrell"),
        Contact(name: "Iben Hvid Moller", username: "@ibenm", avatarName: "AvatarIbenHvidMoller"),
        Contact(name: "Imanni Quansah", username: "@imanni", avatarName: "AvatarImanniQuansah"),
        Contact(name: "James Rhode", username: "@jamesrh", avatarName: "AvatarJamesRhode"),
        Contact(name: "Joao Cardoso", username: "@joaoc", avatarName: "AvatarJoaoCardoso"),
        Contact(name: "Joseph Perez", username: "@josephp", avatarName: "AvatarJosephPerez")
    ]
    
    // Current user as a contact
    var currentUser: Contact {
        Contact(name: "You", username: "@brendon", avatarName: "AvatarProfile")
    }
    
    var hasAssignments: Bool {
        receipt.items.contains { !$0.assignedTo.isEmpty }
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }) {
                        Image("ArrowLeft")
                            .renderingMode(.template)
                            .foregroundColor(themeService.textPrimaryColor)
                            .frame(width: 24, height: 24)
                    }
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    Text("Assign Items")
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 16)
                .frame(height: 64)
                
                // Instructions
                Text("Tap each item to assign it to people")
                    .font(.custom("Inter-Regular", size: 14))
                    .foregroundColor(themeService.textSecondaryColor)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                
                // Items list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(receipt.items.enumerated()), id: \.element.id) { index, item in
                            ReceiptItemRow(
                                item: item,
                                onTap: {
                                    selectedItemIndex = index
                                    showContactPicker = true
                                }
                            )
                        }
                        
                        // Tax row if present
                        if receipt.tax != nil {
                            HStack {
                                Text("Tax")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                                
                                Spacer()
                                
                                Text(receipt.formattedTax ?? "")
                                    .font(.custom("Inter-Medium", size: 16))
                                    .foregroundColor(themeService.textSecondaryColor)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        // Divider
                        Rectangle()
                            .fill(Color(hex: "EEEEEE"))
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        
                        // Total row
                        HStack {
                            Text("Total")
                                .font(.custom("Inter-Bold", size: 18))
                                .foregroundColor(themeService.textPrimaryColor)
                            
                            Spacer()
                            
                            Text(receipt.formattedTotal)
                                .font(.custom("Inter-Bold", size: 18))
                                .foregroundColor(themeService.textPrimaryColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Progress indicator
                        HStack {
                            Text("\(receipt.assignedItemsCount) of \(receipt.items.count) items assigned")
                                .font(.custom("Inter-Medium", size: 14))
                                .foregroundColor(themeService.textSecondaryColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                
                // Bottom button
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        showSummary = true
                    }) {
                        Text("Review Split")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(hasAssignments ? .white : Color.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(hasAssignments ? Color(hex: "080808") : Color(hex: "C8C8C8"))
                            )
                    }
                    .buttonStyle(PressedButtonStyle())
                    .disabled(!hasAssignments)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .background(Color.white)
                }
            }
            
            // Contact picker overlay
            if showContactPicker, let index = selectedItemIndex {
                ItemContactPickerView(
                    isPresented: $showContactPicker,
                    item: receipt.items[index],
                    contacts: [currentUser] + contacts,
                    onSave: { selectedContacts in
                        receipt.items[index].assignedTo = selectedContacts
                    }
                )
                .transition(.move(edge: .bottom))
            }
            
            // Summary view
            if showSummary {
                ReceiptSplitSummaryView(
                    isPresented: $showSummary,
                    receipt: receipt,
                    onDismissAll: onDismissAll
                )
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showContactPicker)
        .animation(.easeInOut(duration: 0.3), value: showSummary)
    }
}

// MARK: - Receipt Item Row

struct ReceiptItemRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let item: ReceiptItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Item name
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.custom("Inter-Bold", size: 16))
                        .foregroundColor(themeService.textPrimaryColor)
                    
                    // Assigned avatars
                    if !item.assignedTo.isEmpty {
                        HStack(spacing: -8) {
                            ForEach(item.assignedTo.prefix(4)) { contact in
                                Image(contact.avatarName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                            
                            if item.assignedTo.count > 4 {
                                Text("+\(item.assignedTo.count - 4)")
                                    .font(.custom("Inter-Bold", size: 10))
                                    .foregroundColor(themeService.textSecondaryColor)
                                    .frame(width: 24, height: 24)
                                    .background(Color(hex: "F5F5F5"))
                                    .clipShape(Circle())
                            }
                        }
                    } else {
                        Text("Tap to assign")
                            .font(.custom("Inter-Regular", size: 12))
                            .foregroundColor(Color(hex: "AAAAAA"))
                    }
                }
                
                Spacer()
                
                // Price
                Text(item.formattedPrice)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeService.textTertiaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                item.isAssigned ? Color(hex: "F8FFF8") : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Item Contact Picker

struct ItemContactPickerView: View {
    @ObservedObject private var themeService = ThemeService.shared
    @Binding var isPresented: Bool
    let item: ReceiptItem
    let contacts: [Contact]
    let onSave: ([Contact]) -> Void
    
    @State private var selectedContacts: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Bottom sheet
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 32, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 16)
                    
                    // Header
                    HStack {
                        Text("Assign \"\(item.name)\"")
                            .font(.custom("Inter-Bold", size: 18))
                            .foregroundColor(themeService.textPrimaryColor)
                        
                        Spacer()
                        
                        Text(item.formattedPrice)
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(themeService.textSecondaryColor)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Contact list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(contacts) { contact in
                                ContactSelectRow(
                                    contact: contact,
                                    isSelected: selectedContacts.contains(contact.id),
                                    onTap: {
                                        if selectedContacts.contains(contact.id) {
                                            selectedContacts.remove(contact.id)
                                        } else {
                                            selectedContacts.insert(contact.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 400)
                    
                    // Done button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        let selected = contacts.filter { selectedContacts.contains($0.id) }
                        onSave(selected)
                        isPresented = false
                    }) {
                        Text("Done")
                            .font(.custom("Inter-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(hex: "080808"))
                            )
                    }
                    .buttonStyle(PressedButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(Color.white)
                .cornerRadius(24, corners: [.topLeft, .topRight])
            }
        }
        .onAppear {
            // Pre-select already assigned contacts
            selectedContacts = Set(item.assignedTo.map { $0.id })
        }
    }
}

// MARK: - Contact Select Row

struct ContactSelectRow: View {
    @ObservedObject private var themeService = ThemeService.shared
    let contact: Contact
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Avatar
                Image(contact.avatarName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                // Name
                Text(contact.name)
                    .font(.custom("Inter-Bold", size: 16))
                    .foregroundColor(themeService.textPrimaryColor)
                
                Spacer()
                
                // Checkbox
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "FF5113"))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color(hex: "CCCCCC"), lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReceiptItemsView(
        isPresented: .constant(true),
        receipt: ScannedReceipt(
            items: [
                ReceiptItem(name: "Burger", price: 12.99, assignedTo: []),
                ReceiptItem(name: "Fries", price: 4.99, assignedTo: []),
                ReceiptItem(name: "Coke", price: 2.99, assignedTo: [])
            ],
            tax: 1.67,
            tip: nil,
            total: 22.64
        ),
        onDismissAll: {}
    )
}
