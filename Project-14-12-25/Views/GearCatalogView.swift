import SwiftUI
import CoreData
import PhotosUI
import UIKit

struct GearCatalogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GearItem.purchaseDate, ascending: false)],
        animation: .default
    ) private var gearItems: FetchedResults<GearItem>
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showAddGear = false
    @State private var showEditGear = false
    @State private var selectedGearItem: GearItem?
    @State private var showDeleteAlert = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage = ""
    
    var totalInvested: Double {
        gearItems.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if gearItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No gear items yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Text("Tap + to add your first gear item")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Total invested card
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total Invested in Gear")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(currencyManager.format(totalInvested))
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(ThemeManager.primaryBlue)
                                    .frame(width: 80, height: 80)
                                    .background(ThemeManager.primaryBlue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                            
                            // Gear items list
                            LazyVStack(spacing: 16) {
                                ForEach(gearItems, id: \.objectID) { item in
                                    GearItemRowView(item: item, onEdit: {
                                        showEditGear = true
                                        selectedGearItem = item
                                    }, onDelete: {
                                        selectedGearItem = item
                                        showDeleteAlert = true
                                    })
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddGear = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(ThemeManager.primaryBlue)
                                .clipShape(Circle())
                                .shadow(color: ThemeManager.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Gear Catalog")
            .sheet(isPresented: $showAddGear) {
                GearItemFormView(item: nil)
            }
            .sheet(isPresented: $showEditGear) {
                if let item = selectedGearItem {
                    GearItemFormView(item: item)
                }
            }
            .alert("Delete Gear Item", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedGearItem = nil
                }
                Button("Delete", role: .destructive) {
                    deleteGearItem()
                }
            } message: {
                if let item = selectedGearItem {
                    Text("Are you sure you want to delete \"\(item.itemDisplayName)\"? This action cannot be undone.")
                }
            }
            .alert("Delete Error", isPresented: $showDeleteErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to delete gear item: \(deleteErrorMessage)")
            }
        }
    }
    
    private func deleteGearItem() {
        guard let item = selectedGearItem else { return }
        
        viewContext.delete(item)
        
        do {
            try PersistenceController.shared.save()
            selectedGearItem = nil
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        }
    }
}

struct GearItemRowView: View {
    let item: GearItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showContextMenu = false
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = item.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeManager.forestGradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "cart.fill")
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.itemDisplayName)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(item.formattedPurchaseDate)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(currencyManager.format(item.price))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(ThemeManager.primaryBlue)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct GearItemFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let item: GearItem?
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var name: String
    @State private var price: String
    @State private var purchaseDate: Date
    @State private var selectedPhoto: UIImage?
    @State private var showImagePicker = false
    @State private var imageSource: ImageSource = .library
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    
    enum ImageSource {
        case camera, library
    }
    
    init(item: GearItem?) {
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _price = State(initialValue: item != nil ? String(item!.price) : "")
        _purchaseDate = State(initialValue: item?.purchaseDate ?? Date())
        
        if let item = item, let photoData = item.photoData {
            _selectedPhoto = State(initialValue: UIImage(data: photoData))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Item Information") {
                    TextField("Item Name", text: $name)
                    
                    HStack {
                        Text("Price")
                        Spacer()
                        TextField("0", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }
                
                Section("Photo (Optional)") {
                    if let photo = selectedPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(alignment: .topTrailing) {
                                Button(action: {
                                    selectedPhoto = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8)
                            }
                    } else {
                        HStack(spacing: 16) {
                            Button(action: {
                                imageSource = .camera
                                showImagePicker = true
                            }) {
                                Label("Camera", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button(action: {
                                imageSource = .library
                                showImagePicker = true
                            }) {
                                Label("Photo Library", systemImage: "photo.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "New Gear Item" : "Edit Gear Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if validateForm() {
                            saveItem()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                if imageSource == .camera {
                    ImagePicker(sourceType: .camera, selectedImage: $selectedPhoto)
                } else {
                    PhotoPicker(selectedImage: $selectedPhoto)
                }
            }
            .alert("Validation Error", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
            .alert("Save Error", isPresented: $showSaveErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to save gear item: \(saveErrorMessage)")
            }
        }
    }
    
    private func validateForm() -> Bool {
        // Validate name
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a name for this gear item"
            showValidationAlert = true
            return false
        }
        
        // Validate price
        if price.isEmpty {
            validationMessage = "Please enter a price for this gear item"
            showValidationAlert = true
            return false
        }
        
        if let priceValue = Double(price), priceValue < 0 {
            validationMessage = "Price cannot be negative"
            showValidationAlert = true
            return false
        }
        
        if Double(price) == nil {
            validationMessage = "Please enter a valid price"
            showValidationAlert = true
            return false
        }
        
        return true
    }
    
    private func saveItem() {
        let itemToSave: GearItem
        
        if let existingItem = item {
            itemToSave = existingItem
        } else {
            itemToSave = GearItem(context: viewContext)
            itemToSave.id = UUID()
        }
        
        itemToSave.name = name.trimmingCharacters(in: .whitespaces)
        itemToSave.price = Double(price) ?? 0
        itemToSave.purchaseDate = purchaseDate
        
        if let photo = selectedPhoto {
            // Optimize image before saving
            let maxDimension: CGFloat = 1200
            let resizedImage = photo.resized(toMaxDimension: maxDimension)
            itemToSave.photoData = resizedImage?.jpegData(compressionQuality: 0.7)
        }
        
        do {
            try PersistenceController.shared.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveErrorAlert = true
        }
    }
}

#Preview {
    GearCatalogView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

