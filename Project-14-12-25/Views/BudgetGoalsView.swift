import SwiftUI
import CoreData

struct BudgetGoalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)],
        animation: .default
    ) private var trips: FetchedResults<FishingTrip>
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @AppStorage("monthlyBudget") private var monthlyBudget: Double = 0
    @AppStorage("yearlyBudget") private var yearlyBudget: Double = 0
    @AppStorage("incomeGoal") private var incomeGoal: Double = 0
    
    var currentMonthSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        return trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.totalExpenses }
    }
    
    var currentYearSpending: Double {
        let calendar = Calendar.current
        let now = Date()
        return trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
            .reduce(0) { $0 + $1.totalExpenses }
    }
    
    var currentYearIncome: Double {
        let calendar = Calendar.current
        let now = Date()
        return trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
            .reduce(0) { $0 + $1.incomeFromSale }
    }
    
    var monthlyProgress: Double {
        guard monthlyBudget > 0 else { return 0 }
        return min(currentMonthSpending / monthlyBudget, 1.0)
    }
    
    var yearlyProgress: Double {
        guard yearlyBudget > 0 else { return 0 }
        return min(currentYearSpending / yearlyBudget, 1.0)
    }
    
    var incomeProgress: Double {
        guard incomeGoal > 0 else { return 0 }
        return min(currentYearIncome / incomeGoal, 1.0)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Monthly Budget") {
                    HStack {
                        Text("Budget")
                        Spacer()
                        TextField("0", value: $monthlyBudget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if monthlyBudget > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Spent this month")
                                Spacer()
                                Text(currencyManager.format(currentMonthSpending))
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: monthlyProgress) {
                                Text("\(Int(monthlyProgress * 100))%")
                                    .font(.system(size: 12))
                            }
                            .tint(monthlyProgress > 1.0 ? .red : ThemeManager.primaryGreen)
                            
                            if monthlyProgress > 1.0 {
                                Text("Over budget by \(currencyManager.format(currentMonthSpending - monthlyBudget))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            } else {
                                Text("Remaining: \(currencyManager.format(monthlyBudget - currentMonthSpending))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Yearly Budget") {
                    HStack {
                        Text("Budget")
                        Spacer()
                        TextField("0", value: $yearlyBudget, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if yearlyBudget > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Spent this year")
                                Spacer()
                                Text(currencyManager.format(currentYearSpending))
                                    .fontWeight(.semibold)
                            }
                            
                            ProgressView(value: yearlyProgress) {
                                Text("\(Int(yearlyProgress * 100))%")
                                    .font(.system(size: 12))
                            }
                            .tint(yearlyProgress > 1.0 ? .red : ThemeManager.primaryGreen)
                            
                            if yearlyProgress > 1.0 {
                                Text("Over budget by \(currencyManager.format(currentYearSpending - yearlyBudget))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            } else {
                                Text("Remaining: \(currencyManager.format(yearlyBudget - currentYearSpending))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Income Goal") {
                    HStack {
                        Text("Goal")
                        Spacer()
                        TextField("0", value: $incomeGoal, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if incomeGoal > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Earned this year")
                                Spacer()
                                Text(currencyManager.format(currentYearIncome))
                                    .fontWeight(.semibold)
                                    .foregroundColor(ThemeManager.primaryGreen)
                            }
                            
                            ProgressView(value: incomeProgress) {
                                Text("\(Int(incomeProgress * 100))%")
                                    .font(.system(size: 12))
                            }
                            .tint(ThemeManager.primaryGreen)
                            
                            if incomeProgress >= 1.0 {
                                Text("Goal achieved! 🎉")
                                    .font(.system(size: 12))
                                    .foregroundColor(ThemeManager.primaryGreen)
                            } else {
                                Text("Remaining: \(currencyManager.format(incomeGoal - currentYearIncome))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Budget & Goals")
        }
    }
}

#Preview {
    BudgetGoalsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

