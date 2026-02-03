import Foundation

enum Currency: String, CaseIterable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case rub = "RUB"
    case custom = "Custom"
    
    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .rub: return "₽"
        case .custom: return "$"
        }
    }
}

class CurrencyManager: ObservableObject {
    @Published var currentCurrency: Currency {
        didSet {
            UserDefaults.standard.set(currentCurrency.rawValue, forKey: "selectedCurrency")
        }
    }
    
    @Published var customSymbol: String {
        didSet {
            UserDefaults.standard.set(customSymbol, forKey: "customCurrencySymbol")
        }
    }
    
    static let shared = CurrencyManager()
    
    init() {
        if let savedCurrency = UserDefaults.standard.string(forKey: "selectedCurrency"),
           let currency = Currency(rawValue: savedCurrency) {
            self.currentCurrency = currency
        } else {
            self.currentCurrency = .usd
        }
        
        self.customSymbol = UserDefaults.standard.string(forKey: "customCurrencySymbol") ?? "$"
    }
    
    func format(_ amount: Double) -> String {
        let symbol = currentCurrency == .custom ? customSymbol : currentCurrency.symbol
        return String(format: "%.2f", amount).replacingOccurrences(of: ".00", with: "") + " " + symbol
    }
}

