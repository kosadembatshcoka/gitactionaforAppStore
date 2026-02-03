import SwiftUI
import CoreData
import UIKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var currencyManager = CurrencyManager.shared
    
    @State private var showResetAlert = false
    @State private var resetConfirmationCount = 0
    @State private var showExportSheet = false
    @State private var showCSVExportSheet = false
    @State private var csvExportURL: URL?
    @State private var showCSVErrorAlert = false
    @State private var csvErrorMessage = ""
    @State private var showPDFErrorAlert = false
    @State private var pdfErrorMessage = ""
    @State private var showSaveErrorAlert = false
    @State private var saveErrorMessage = ""
    @State private var pdfExportURL: URL?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $themeManager.currentTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                }
                
                Section("Currency") {
                    Picker("Currency", selection: $currencyManager.currentCurrency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.rawValue)").tag(currency)
                        }
                    }
                    
                    if currencyManager.currentCurrency == .custom {
                        TextField("Custom Symbol", text: $currencyManager.customSymbol)
                    }
                }
                
                Section("Data") {
                    Button(action: {
                        do {
                            if let pdfURL = try generateFullPDF() {
                                pdfExportURL = pdfURL
                                showExportSheet = true
                                AppLogger.shared.info("PDF export initiated successfully")
                            }
                        } catch {
                            pdfErrorMessage = error.localizedDescription
                            showPDFErrorAlert = true
                            AppLogger.shared.error("PDF export failed: \(pdfErrorMessage)")
                        }
                    }) {
                        HStack {
                            Label("Export All Data as PDF", systemImage: "doc.fill")
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        do {
                            let csvURL = try ExportManager.shared.exportToCSV(context: viewContext, currencyManager: currencyManager)
                            csvExportURL = csvURL
                            showCSVExportSheet = true
                            AppLogger.shared.info("CSV export initiated successfully")
                        } catch let error as ExportError {
                            csvErrorMessage = error.errorDescription ?? error.localizedDescription
                            showCSVErrorAlert = true
                            AppLogger.shared.error("CSV export failed: \(csvErrorMessage)")
                        } catch {
                            csvErrorMessage = error.localizedDescription
                            showCSVErrorAlert = true
                            AppLogger.shared.error("CSV export failed with unknown error: \(error.localizedDescription)")
                        }
                    }) {
                        HStack {
                            Label("Export All Data as CSV", systemImage: "tablecells.fill")
                            Spacer()
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showResetAlert = true
                    }) {
                        HStack {
                            Label("Reset All Data", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Angler Finance Tracker")
                        Spacer()
                        Text("Track your fishing finances")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {
                    resetConfirmationCount = 0
                }
                Button("Reset", role: .destructive) {
                    handleReset()
                }
            } message: {
                if resetConfirmationCount == 0 {
                    Text("This will delete all trips and gear items. This action cannot be undone. Are you sure?")
                } else if resetConfirmationCount == 1 {
                    Text("This is your second confirmation. One more to permanently delete all data.")
                } else {
                    Text("Final confirmation. All data will be permanently deleted.")
                }
            }
            .sheet(isPresented: $showExportSheet) {
                if let pdfURL = pdfExportURL {
                    ShareSheet(activityItems: [pdfURL]) {
                        // Cleanup after sharing
                        cleanupTempFile(pdfURL)
                    }
                }
            }
            .sheet(isPresented: $showCSVExportSheet) {
                if let csvURL = csvExportURL {
                    ShareSheet(activityItems: [csvURL]) {
                        // Cleanup after sharing
                        cleanupTempFile(csvURL)
                    }
                }
            }
            .alert("CSV Export Error", isPresented: $showCSVErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(csvErrorMessage)
            }
            .alert("PDF Export Error", isPresented: $showPDFErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pdfErrorMessage)
            }
            .alert("Save Error", isPresented: $showSaveErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Failed to reset data: \(saveErrorMessage)")
            }
        }
    }
    
    private func handleReset() {
        resetConfirmationCount += 1
        
        if resetConfirmationCount >= 3 {
            // Delete all trips
            let tripFetch: NSFetchRequest<FishingTrip> = FishingTrip.fetchRequest()
            do {
                let trips = try viewContext.fetch(tripFetch)
                trips.forEach { viewContext.delete($0) }
            } catch {
                AppLogger.shared.error("Failed to fetch trips: \(error.localizedDescription)")
            }
            
            // Delete all gear items
            let gearFetch: NSFetchRequest<GearItem> = GearItem.fetchRequest()
            do {
                let gearItems = try viewContext.fetch(gearFetch)
                gearItems.forEach { viewContext.delete($0) }
            } catch {
                AppLogger.shared.error("Failed to fetch gear items: \(error.localizedDescription)")
            }
            
            do {
                try PersistenceController.shared.save()
                resetConfirmationCount = 0
            } catch {
                saveErrorMessage = error.localizedDescription
                showSaveErrorAlert = true
                resetConfirmationCount = 0
            }
        }
    }
    
    private func cleanupTempFile(_ url: URL) {
        DispatchQueue.global(qos: .utility).async {
            do {
                try FileManager.default.removeItem(at: url)
                AppLogger.shared.debug("Cleaned up temporary export file: \(url.lastPathComponent)")
            } catch {
                AppLogger.shared.warning("Failed to cleanup temporary file: \(error.localizedDescription)")
            }
        }
    }
    
    private func generateFullPDF() throws -> URL? {
        do {
            // Clean up old files first
            ExportManager.shared.cleanupOldExports()
            
            // Fetch all trips
            let tripFetch: NSFetchRequest<FishingTrip> = FishingTrip.fetchRequest()
            tripFetch.sortDescriptors = [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)]
            let trips: [FishingTrip]
            do {
                trips = try viewContext.fetch(tripFetch)
                AppLogger.shared.debug("Fetched \(trips.count) trips for PDF export")
            } catch {
                let errorMsg = "Failed to fetch trips: \(error.localizedDescription)"
                AppLogger.shared.error(errorMsg)
                throw NSError(domain: "PDFExport", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            
            guard !trips.isEmpty else {
                let errorMsg = "No trips to export"
                AppLogger.shared.warning(errorMsg)
                throw NSError(domain: "PDFExport", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
            let data = pdfRenderer.pdfData { context in
                context.beginPage()
                
                var yPosition: CGFloat = 50
                
                // Title
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 28),
                    .foregroundColor: UIColor.label
                ]
                "My Fishing Finances 2025".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
                yPosition += 50
                
                // Summary
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.label
                ]
                "Summary".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: summaryAttributes)
                yPosition += 30
                
                let totalExpenses = trips.reduce(0) { $0 + $1.totalExpenses }
                let totalIncome = trips.reduce(0) { $0 + $1.incomeFromSale }
                let netBalance = totalIncome - totalExpenses
                
                let detailAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label
                ]
                
                let summaryDetails = [
                    "Total Trips: \(trips.count)",
                    "Total Expenses: \(currencyManager.format(totalExpenses))",
                    "Total Income: \(currencyManager.format(totalIncome))",
                    "Net Balance: \(currencyManager.format(netBalance))"
                ]
                
                for detail in summaryDetails {
                    detail.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: detailAttributes)
                    yPosition += 25
                }
                
                yPosition += 20
                
                // Trips list
                "All Trips".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: summaryAttributes)
                yPosition += 30
                
                for trip in trips {
                    if yPosition > 750 {
                        context.beginPage()
                        yPosition = 50
                    }
                    
                    let tripText = "\(trip.formattedDate) - \(trip.locationDisplayName) - \(currencyManager.format(trip.netBalance))"
                    tripText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: detailAttributes)
                    yPosition += 20
                }
            }
            
            let timestamp = Int(Date().timeIntervalSince1970)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("My_Fishing_Finances_\(timestamp).pdf")
            try data.write(to: tempURL)
            AppLogger.shared.info("PDF export completed successfully: \(tempURL.lastPathComponent)")
            return tempURL
        } catch {
            let errorMsg = "Failed to generate PDF: \(error.localizedDescription)"
            AppLogger.shared.error(errorMsg)
            throw NSError(domain: "PDFExport", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }
}


