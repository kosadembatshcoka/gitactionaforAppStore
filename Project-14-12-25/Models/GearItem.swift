import Foundation
import CoreData

@objc(GearItem)
public class GearItem: NSManagedObject {
    
}

extension GearItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<GearItem> {
        return NSFetchRequest<GearItem>(entityName: "GearItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var price: Double
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var photoData: Data?
    
    var formattedPurchaseDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: purchaseDate ?? Date())
    }
    
    var itemDisplayName: String {
        name?.isEmpty == false ? name! : "Unnamed Item"
    }
}

