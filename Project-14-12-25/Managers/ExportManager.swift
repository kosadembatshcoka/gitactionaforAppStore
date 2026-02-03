import Foundation
import CoreData

enum ExportError: LocalizedError {
    case fetchFailed(String)
    case writeFailed(String)
    case noData
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch trips: \(message)"
        case .writeFailed(let message):
            return "Failed to write CSV file: \(message)"
        case .noData:
            return "No trips to export"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    // Clean up old temporary export files (older than 24 hours)
    func cleanupOldExports() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: [.creationDateKey], options: [])
            let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            
            for file in files {
                if file.pathExtension == "csv" || file.pathExtension == "pdf" {
                    if let attributes = try? file.resourceValues(forKeys: [.creationDateKey]),
                       let creationDate = attributes.creationDate,
                       creationDate < oneDayAgo {
                        try? fileManager.removeItem(at: file)
                        AppLogger.shared.debug("Cleaned up old export file: \(file.lastPathComponent)")
                    }
                }
            }
        } catch {
            AppLogger.shared.warning("Failed to cleanup old export files: \(error.localizedDescription)")
        }
    }
    
    func exportToCSV(context: NSManagedObjectContext, currencyManager: CurrencyManager) throws -> URL {
        AppLogger.shared.info("Starting CSV export")
        
        // Clean up old files first
        cleanupOldExports()
        
        let fetchRequest: NSFetchRequest<FishingTrip> = FishingTrip.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)]
        
        let trips: [FishingTrip]
        do {
            trips = try context.fetch(fetchRequest)
            AppLogger.shared.debug("Fetched \(trips.count) trips for export")
        } catch {
            AppLogger.shared.error("Failed to fetch trips: \(error.localizedDescription)")
            throw ExportError.fetchFailed(error.localizedDescription)
        }
        
        guard !trips.isEmpty else {
            AppLogger.shared.warning("No trips to export")
            throw ExportError.noData
        }
        
        var csvString = "Date,Location,Fuel,Bait,License,Boat Rental,Food,Other Expenses,Total Expenses,Income,Net Balance,Fish Caught,Weather,Temperature,Notes\n"
        
        for trip in trips {
            guard let date = trip.date else {
                AppLogger.shared.warning("Trip missing date, skipping")
                continue
            }
            
            let dateString = trip.formattedDate
            let location = (trip.locationDisplayName ?? "Unknown").replacingOccurrences(of: ",", with: ";")
            let fuel = String(trip.fuel)
            let bait = String(trip.bait)
            let license = String(trip.license)
            let boat = String(trip.boat)
            let food = String(trip.food)
            let other = String(trip.otherExpenses)
            let totalExpenses = String(trip.totalExpenses)
            let income = String(trip.incomeFromSale)
            let netBalance = String(trip.netBalance)
            let fishCaught = trip.fishCaught?.replacingOccurrences(of: ",", with: ";") ?? ""
            let weather = trip.weatherCondition?.replacingOccurrences(of: ",", with: ";") ?? ""
            let temperature = String(trip.temperature)
            let notes = trip.note?.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "\r", with: " ") ?? ""
            
            csvString += "\(dateString),\(location),\(fuel),\(bait),\(license),\(boat),\(food),\(other),\(totalExpenses),\(income),\(netBalance),\(fishCaught),\(weather),\(temperature),\(notes)\n"
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("Fishing_Trips_Export_\(timestamp).csv")
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            AppLogger.shared.info("CSV export completed successfully: \(tempURL.lastPathComponent)")
            return tempURL
        } catch {
            AppLogger.shared.error("Failed to write CSV file: \(error.localizedDescription)")
            throw ExportError.writeFailed(error.localizedDescription)
        }
    }
}

