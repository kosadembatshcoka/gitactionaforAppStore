import CoreData
import Foundation

enum PersistenceError: LocalizedError {
    case loadFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let message):
            return "Failed to load data: \(message)"
        case .saveFailed(let message):
            return "Failed to save data: \(message)"
        }
    }
}

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    @Published var lastError: PersistenceError?
    @Published var hasError: Bool = false
    @Published var isLoading: Bool = true
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AnglerFinanceTracker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { [weak self] description, error in
            if let error = error {
                let errorMessage = error.localizedDescription
                AppLogger.shared.error("Core Data failed to load: \(errorMessage)")
                
                // Log detailed error information
                if let nsError = error as NSError? {
                    AppLogger.shared.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                    AppLogger.shared.debug("Error userInfo: \(nsError.userInfo)")
                }
                
                DispatchQueue.main.async {
                    self?.lastError = .loadFailed(errorMessage)
                    self?.hasError = true
                    self?.isLoading = false
                }
            } else {
                AppLogger.shared.info("Core Data loaded successfully")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
            AppLogger.shared.debug("Context saved successfully")
        } catch {
            let nsError = error as NSError
            let errorMessage = "\(nsError.localizedDescription)"
            
            AppLogger.shared.error("Failed to save context: \(errorMessage)")
            AppLogger.shared.debug("Error domain: \(nsError.domain), code: \(nsError.code)")
            
            // Rollback changes on error
            context.rollback()
            
            let persistenceError = PersistenceError.saveFailed(errorMessage)
            DispatchQueue.main.async {
                self.lastError = persistenceError
                self.hasError = true
            }
            
            throw persistenceError
        }
    }
    
    func saveIfNeeded() -> Bool {
        do {
            try save()
            return true
        } catch {
            return false
        }
    }
}

