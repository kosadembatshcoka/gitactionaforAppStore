import SwiftUI
import CoreData
import PhotosUI
import UIKit

struct TripFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let trip: FishingTrip?
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var date: Date
    @State private var locationName: String
    @State private var fuel: String
    @State private var bait: String
    @State private var license: String
    @State private var boat: String
    @State private var food: String
    @State private var otherExpenses: String
    @State private var incomeFromSale: String
    @State private var note: String
    @State private var fishCaught: String
    @State private var weatherCondition: String
    @State private var temperature: String
    @State private var selectedPhoto: UIImage?
    @State private var showImagePicker = false
    @State private var imageSource: ImageSource = .library
    
    enum ImageSource {
        case camera, library
    }
    
    init(trip: FishingTrip?) {
        self.trip = trip
        _date = State(initialValue: trip?.date ?? Date())
        _locationName = State(initialValue: trip?.locationName ?? "")
        _fuel = State(initialValue: trip != nil ? String(trip!.fuel) : "")
        _bait = State(initialValue: trip != nil ? String(trip!.bait) : "")
        _license = State(initialValue: trip != nil ? String(trip!.license) : "")
        _boat = State(initialValue: trip != nil ? String(trip!.boat) : "")
        _food = State(initialValue: trip != nil ? String(trip!.food) : "")
        _otherExpenses = State(initialValue: trip != nil ? String(trip!.otherExpenses) : "")
        _incomeFromSale = State(initialValue: trip != nil ? String(trip!.incomeFromSale) : "")
        _note = State(initialValue: trip?.note ?? "")
        _fishCaught = State(initialValue: trip?.fishCaught ?? "")
        _weatherCondition = State(initialValue: trip?.weatherCondition ?? "")
        _temperature = State(initialValue: trip != nil ? String(trip!.temperature) : "")
        
        if let trip = trip, let photoData = trip.photoData {
            _selectedPhoto = State(initialValue: UIImage(data: photoData))
        }
    }
    
    var netBalance: Double {
        let fuelAmount = Double(fuel) ?? 0
        let baitAmount = Double(bait) ?? 0
        let licenseAmount = Double(license) ?? 0
        let boatAmount = Double(boat) ?? 0
        let foodAmount = Double(food) ?? 0
        let otherAmount = Double(otherExpenses) ?? 0
        
        let expenses = fuelAmount + baitAmount + licenseAmount + boatAmount + foodAmount + otherAmount
        let income = Double(incomeFromSale) ?? 0
        return income - expenses
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Trip Information") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Location / Water Body", text: $locationName)
                    
                    // Photo picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photo (Optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
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
                
                Section("Expenses") {
                    ExpenseField(title: "Fuel", value: $fuel, icon: "car.fill")
                    ExpenseField(title: "Bait & Lures", value: $bait, icon: "fish.fill")
                    ExpenseField(title: "License / Permit", value: $license, icon: "doc.text.fill")
                    ExpenseField(title: "Boat Rental", value: $boat, icon: "sailboat.fill")
                    ExpenseField(title: "Food & Drinks", value: $food, icon: "fork.knife")
                    ExpenseField(title: "Other Expenses", value: $otherExpenses, icon: "ellipsis.circle.fill")
                }
                
                Section("Income") {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(ThemeManager.primaryGreen)
                        TextField("Sold Catch", text: $incomeFromSale)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Catch Details") {
                    TextField("Fish Caught (e.g., Bass, Trout)", text: $fishCaught)
                    
                    Picker("Weather", selection: $weatherCondition) {
                        Text("Select weather").tag("")
                        Text("Sunny").tag("Sunny")
                        Text("Cloudy").tag("Cloudy")
                        Text("Rainy").tag("Rainy")
                        Text("Windy").tag("Windy")
                        Text("Foggy").tag("Foggy")
                        Text("Snowy").tag("Snowy")
                    }
                    
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(ThemeManager.primaryBlue)
                        TextField("Temperature (°F)", text: $temperature)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }
                
                Section {
                    HStack {
                        Text("Net Balance")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Text(currencyManager.format(netBalance))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(netBalance >= 0 ? ThemeManager.primaryGreen : .red)
                    }
                }
            }
            .navigationTitle(trip == nil ? "New Trip" : "Edit Trip")
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
                            saveTrip()
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
                Text("Failed to save trip: \(saveErrorMessage)")
            }
            .alert("Image Error", isPresented: $showImageErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(imageErrorMessage)
            }
        }
    }
    
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var showImageErrorAlert = false
    @State private var imageErrorMessage = ""
    
    private func validateForm() -> Bool {
        // Basic validation - location is required
        if locationName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationMessage = "Please enter a location for this trip"
            showValidationAlert = true
            return false
        }
        
        // Check if all expense fields are valid numbers and non-negative
        let expenseFields: [(String, String)] = [
            ("Fuel", fuel),
            ("Bait & Lures", bait),
            ("License/Permit", license),
            ("Boat Rental", boat),
            ("Food & Drinks", food),
            ("Other Expenses", otherExpenses)
        ]
        
        for (fieldName, fieldValue) in expenseFields {
            if !fieldValue.isEmpty {
                guard let value = Double(fieldValue) else {
                    validationMessage = "Please enter a valid number for \(fieldName)"
                    showValidationAlert = true
                    return false
                }
                if value < 0 {
                    validationMessage = "\(fieldName) cannot be negative"
                    showValidationAlert = true
                    return false
                }
            }
        }
        
        // Validate income (can be 0 or positive)
        if !incomeFromSale.isEmpty {
            guard let income = Double(incomeFromSale) else {
                validationMessage = "Please enter a valid number for income"
                showValidationAlert = true
                return false
            }
            if income < 0 {
                validationMessage = "Income cannot be negative"
                showValidationAlert = true
                return false
            }
        }
        
        // Validate temperature if provided
        if !temperature.isEmpty {
            guard let temp = Double(temperature) else {
                validationMessage = "Please enter a valid temperature"
                showValidationAlert = true
                return false
            }
            // Temperature can be negative (below freezing)
        }
        
        return true
    }
    
    private func saveTrip() {
        let tripToSave: FishingTrip
        
        if let existingTrip = trip {
            tripToSave = existingTrip
        } else {
            tripToSave = FishingTrip(context: viewContext)
            tripToSave.id = UUID()
        }
        
        tripToSave.date = date
        tripToSave.locationName = locationName.isEmpty ? nil : locationName
        tripToSave.fuel = Double(fuel) ?? 0
        tripToSave.bait = Double(bait) ?? 0
        tripToSave.license = Double(license) ?? 0
        tripToSave.boat = Double(boat) ?? 0
        tripToSave.food = Double(food) ?? 0
        tripToSave.otherExpenses = Double(otherExpenses) ?? 0
        tripToSave.incomeFromSale = Double(incomeFromSale) ?? 0
        tripToSave.note = note.isEmpty ? nil : note
        tripToSave.fishCaught = fishCaught.isEmpty ? nil : fishCaught
        tripToSave.weatherCondition = weatherCondition.isEmpty ? nil : weatherCondition
        tripToSave.temperature = Double(temperature) ?? 0
        
        if let photo = selectedPhoto {
            // Optimize image before saving
            let maxDimension: CGFloat = 1200
            let resizedImage = photo.resized(toMaxDimension: maxDimension)
            tripToSave.photoData = resizedImage?.jpegData(compressionQuality: 0.7)
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

struct ExpenseField: View {
    let title: String
    @Binding var value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.primaryBlue)
                .frame(width: 24)
            TextField(title, text: $value)
                .keyboardType(.decimalPad)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            } else {
                AppLogger.shared.warning("Failed to get image from picker")
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            AppLogger.shared.error("Failed to load image: \(error.localizedDescription)")
                            // Could show error to user here if needed
                        } else if let image = image as? UIImage {
                            self?.parent.selectedImage = image
                        } else {
                            AppLogger.shared.warning("Failed to convert to UIImage")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    return TripFormView(trip: nil)
        .environment(\.managedObjectContext, context)
}

