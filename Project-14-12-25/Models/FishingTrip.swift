import Foundation
import CoreData

@objc(FishingTrip)
public class FishingTrip: NSManagedObject {
    
}

extension FishingTrip {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FishingTrip> {
        return NSFetchRequest<FishingTrip>(entityName: "FishingTrip")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var locationName: String?
    @NSManaged public var photoData: Data?
    @NSManaged public var fuel: Double
    @NSManaged public var bait: Double
    @NSManaged public var license: Double
    @NSManaged public var boat: Double
    @NSManaged public var food: Double
    @NSManaged public var otherExpenses: Double
    @NSManaged public var incomeFromSale: Double
    @NSManaged public var note: String?
    @NSManaged public var fishCaught: String?
    @NSManaged public var weatherCondition: String?
    @NSManaged public var temperature: Double
    
    var netBalance: Double {
        incomeFromSale - totalExpenses
    }
    
    var totalExpenses: Double {
        fuel + bait + license + boat + food + otherExpenses
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date ?? Date())
    }
    
    var locationDisplayName: String {
        locationName?.isEmpty == false ? locationName! : "Unknown Location"
    }
}

