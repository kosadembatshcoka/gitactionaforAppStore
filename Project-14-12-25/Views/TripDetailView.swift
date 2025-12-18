import SwiftUI
import CoreData
import UIKit

struct TripDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let trip: FishingTrip
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var showPDFErrorAlert = false
    @State private var pdfErrorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Photo header
                if let photoData = trip.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipped()
                } else {
                    ThemeManager.waterGradient
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "fish.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                
                VStack(spacing: 24) {
                    // Header info
                    VStack(spacing: 12) {
                        Text(trip.locationDisplayName)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text(trip.formattedDate)
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                        
                        // Weather and fish info
                        if trip.weatherCondition != nil || trip.fishCaught != nil {
                            HStack(spacing: 16) {
                                if let weather = trip.weatherCondition, !weather.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: weatherIcon(for: weather))
                                        Text(weather)
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                }
                                
                                if trip.temperature > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "thermometer")
                                        Text("\(Int(trip.temperature))°F")
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                }
                                
                                if let fish = trip.fishCaught, !fish.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "fish.fill")
                                        Text(fish)
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(ThemeManager.primaryGreen)
                                }
                            }
                            .padding(.top, 4)
                        }
                        
                        // Net balance
                        Text(currencyManager.format(trip.netBalance))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(trip.netBalance >= 0 ? ThemeManager.primaryGreen : .red)
                            .padding(.top, 8)
                    }
                    .padding(.top, 24)
                    
                    // Expenses breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Expenses")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                        
                        ExpenseRow(title: "Fuel", amount: trip.fuel, icon: "car.fill")
                        ExpenseRow(title: "Bait & Lures", amount: trip.bait, icon: "fish.fill")
                        ExpenseRow(title: "License / Permit", amount: trip.license, icon: "doc.text.fill")
                        ExpenseRow(title: "Boat Rental", amount: trip.boat, icon: "sailboat.fill")
                        ExpenseRow(title: "Food & Drinks", amount: trip.food, icon: "fork.knife")
                        ExpenseRow(title: "Other Expenses", amount: trip.otherExpenses, icon: "ellipsis.circle.fill")
                        
                        Divider()
                            .padding(.horizontal)
                        
                        HStack {
                            Text("Total Expenses")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Text(currencyManager.format(trip.totalExpenses))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    
                    // Income
                    if trip.incomeFromSale > 0 {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Income")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(ThemeManager.primaryGreen)
                                    .font(.system(size: 24))
                                Text("Sold Catch")
                                    .font(.system(size: 18, weight: .medium))
                                Spacer()
                                Text(currencyManager.format(trip.incomeFromSale))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(ThemeManager.primaryGreen)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                    }
                    
                    // Notes
                    if let note = trip.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal)
                            
                            Text(note)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        if generatePDF() != nil {
                            showShareSheet = true
                        }
                    }) {
                        Label("Share PDF", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TripFormView(trip: trip)
        }
        .alert("Delete Trip", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfURL = generatePDF() {
                ShareSheet(activityItems: [pdfURL]) {
                    // Cleanup after sharing
                    cleanupTempFile(pdfURL)
                }
            }
        }
        .alert("Save Error", isPresented: $showSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to delete trip: \(saveErrorMessage)")
        }
        .alert("PDF Export Error", isPresented: $showPDFErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to generate PDF: \(pdfErrorMessage)")
        }
    }
    
    private func deleteTrip() {
        viewContext.delete(trip)
        do {
            try PersistenceController.shared.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
            showSaveErrorAlert = true
        }
    }
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "sunny": return "sun.max.fill"
        case "cloudy": return "cloud.fill"
        case "rainy": return "cloud.rain.fill"
        case "windy": return "wind"
        case "foggy": return "cloud.fog.fill"
        case "snowy": return "cloud.snow.fill"
        default: return "cloud.fill"
        }
    }
    
    private func cleanupTempFile(_ url: URL) {
        DispatchQueue.global(qos: .utility).async {
            do {
                try FileManager.default.removeItem(at: url)
                AppLogger.shared.debug("Cleaned up temporary PDF file: \(url.lastPathComponent)")
            } catch {
                AppLogger.shared.warning("Failed to cleanup temporary file: \(error.localizedDescription)")
            }
        }
    }
    
    private func generatePDF() -> URL? {
        do {
            AppLogger.shared.info("Generating PDF for trip: \(trip.locationDisplayName)")
            
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
            let data = pdfRenderer.pdfData { context in
                context.beginPage()
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.label
                ]
                
                var yPosition: CGFloat = 50
                
                // Title
                "Fishing Trip Summary".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                yPosition += 40
                
                // Trip details
                let detailAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.label
                ]
                
                let details = [
                    "Location: \(trip.locationDisplayName)",
                    "Date: \(trip.formattedDate)",
                    "Total Expenses: \(currencyManager.format(trip.totalExpenses))",
                    "Income: \(currencyManager.format(trip.incomeFromSale))",
                    "Net Balance: \(currencyManager.format(trip.netBalance))"
                ]
                
                for detail in details {
                    detail.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: detailAttributes)
                    yPosition += 30
                }
            }
            
            let timestamp = Int(Date().timeIntervalSince1970)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("trip_summary_\(timestamp).pdf")
            try data.write(to: tempURL)
            AppLogger.shared.info("PDF generated successfully: \(tempURL.lastPathComponent)")
            return tempURL
        } catch {
            pdfErrorMessage = error.localizedDescription
            showPDFErrorAlert = true
            AppLogger.shared.error("Failed to generate PDF: \(error.localizedDescription)")
            return nil
        }
    }
}

struct ExpenseRow: View {
    let title: String
    let amount: Double
    let icon: String
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(ThemeManager.primaryBlue)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 16))
            Spacer()
            Text(currencyManager.format(amount))
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.horizontal)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let onDismiss: (() -> Void)?
    
    init(activityItems: [Any], onDismiss: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.onDismiss = onDismiss
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        TripDetailView(trip: FishingTrip(context: PersistenceController.shared.container.viewContext))
    }
    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

