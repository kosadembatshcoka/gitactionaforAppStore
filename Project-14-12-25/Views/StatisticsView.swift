import SwiftUI
import CoreData
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)],
        animation: .default
    ) private var trips: FetchedResults<FishingTrip>
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var cachedStats: StatisticsCache?
    
    // Cache structure for computed statistics
    private struct StatisticsCache {
        let monthlyData: [MonthlyData]
        let topExpensiveLocations: [(String, Double)]
        let topProfitableLocations: [(String, Double)]
        let averageCostPerTrip: Double
        let tripsThisYear: Int
        let yearComparison: (thisYear: Double, lastYear: Double)
        let fishStatistics: [(String, Int)]
        let weatherStatistics: [(String, Int)]
        let tripsCount: Int
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Monthly expenses/income chart
                    monthlyChartSection
                    
                    // Top locations
                    topLocationsSection
                    
                    // Averages
                    averagesSection
                    
                    // Year comparison
                    yearComparisonSection
                    
                    // Fish caught statistics
                    fishStatisticsSection
                    
                    // Weather statistics
                    weatherStatisticsSection
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                updateCache()
            }
            .onChange(of: trips.count) { _ in
                updateCache()
            }
        }
    }
    
    private func updateCache() {
        let cache = StatisticsCache(
            monthlyData: computeMonthlyData(),
            topExpensiveLocations: computeTopExpensiveLocations(),
            topProfitableLocations: computeTopProfitableLocations(),
            averageCostPerTrip: computeAverageCostPerTrip(),
            tripsThisYear: computeTripsThisYear(),
            yearComparison: computeYearComparison(),
            fishStatistics: computeFishStatistics(),
            weatherStatistics: computeWeatherStatistics(),
            tripsCount: trips.count
        )
        cachedStats = cache
    }
    
    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Overview")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            let data = cachedStats?.monthlyData ?? []
            if !data.isEmpty {
                Chart(data) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.expenses),
                        stacking: .unstacked
                    )
                    .foregroundStyle(ThemeManager.primaryBlue.opacity(0.7))
                    
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Amount", data.income),
                        stacking: .unstacked
                    )
                    .foregroundStyle(ThemeManager.primaryGreen.opacity(0.7))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(currencyManager.format(doubleValue))
                                    .font(.system(size: 10))
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private var topLocationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Locations")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            let topExpensive = cachedStats?.topExpensiveLocations ?? []
            let topProfitable = cachedStats?.topProfitableLocations ?? []
            
            if !topExpensive.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Expensive")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(topExpensive.prefix(5)), id: \.0) { location, amount in
                        HStack {
                            Text(location)
                                .font(.system(size: 16))
                            Spacer()
                            Text(currencyManager.format(amount))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ThemeManager.primaryBlue)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            if !topProfitable.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Profitable")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(topProfitable.prefix(5)), id: \.0) { location, profit in
                        HStack {
                            Text(location)
                                .font(.system(size: 16))
                            Spacer()
                            Text(currencyManager.format(profit))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(ThemeManager.primaryGreen)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private var averagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Averages")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            HStack(spacing: 16) {
                StatBox(
                    title: "Cost per Trip",
                    value: currencyManager.format(cachedStats?.averageCostPerTrip ?? 0),
                    color: ThemeManager.primaryBlue
                )
                
                StatBox(
                    title: "Trips This Year",
                    value: String(cachedStats?.tripsThisYear ?? 0),
                    color: ThemeManager.primaryGreen
                )
            }
        }
    }
    
    private var yearComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Year Comparison")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            let comparison = cachedStats?.yearComparison ?? (thisYear: 0, lastYear: 0)
            
            VStack(spacing: 12) {
                ComparisonRow(year: "This Year", amount: comparison.thisYear, color: ThemeManager.primaryGreen)
                ComparisonRow(year: "Last Year", amount: comparison.lastYear, color: ThemeManager.primaryBlue)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
    
    // Computed properties (now used only for cache computation)
    private func computeMonthlyData() -> [MonthlyData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: trips) { trip -> String in
            guard let date = trip.date else { return "" }
            let components = calendar.dateComponents([.year, .month], from: date)
            return "\(components.year ?? 0)-\(String(format: "%02d", components.month ?? 0))"
        }
        
        return grouped.map { key, trips in
            let expenses = trips.reduce(0) { $0 + $1.totalExpenses }
            let income = trips.reduce(0) { $0 + $1.incomeFromSale }
            return MonthlyData(month: key, expenses: expenses, income: income)
        }
        .sorted { $0.month < $1.month }
    }
    
    private func computeTopExpensiveLocations() -> [(String, Double)] {
        let grouped = Dictionary(grouping: trips) { $0.locationDisplayName }
        return grouped.map { location, trips in
            let total = trips.reduce(0) { $0 + $1.totalExpenses }
            return (location, total)
        }
        .sorted { $0.1 > $1.1 }
    }
    
    private func computeTopProfitableLocations() -> [(String, Double)] {
        let grouped = Dictionary(grouping: trips) { $0.locationDisplayName }
        return grouped.map { location, trips in
            let profit = trips.reduce(0) { $0 + $1.netBalance }
            return (location, profit)
        }
        .sorted { $0.1 > $1.1 }
    }
    
    private func computeAverageCostPerTrip() -> Double {
        guard !trips.isEmpty else { return 0 }
        let total = trips.reduce(0) { $0 + $1.totalExpenses }
        return total / Double(trips.count)
    }
    
    private func computeTripsThisYear() -> Int {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        return trips.filter { trip in
            guard let date = trip.date else { return false }
            return calendar.component(.year, from: date) == thisYear
        }.count
    }
    
    private func computeYearComparison() -> (thisYear: Double, lastYear: Double) {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        let lastYear = thisYear - 1
        
        let thisYearTotal = trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.component(.year, from: date) == thisYear
            }
            .reduce(0) { $0 + $1.netBalance }
        
        let lastYearTotal = trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.component(.year, from: date) == lastYear
            }
            .reduce(0) { $0 + $1.netBalance }
        
        return (thisYearTotal, lastYearTotal)
    }
    
    private var fishStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fish Caught")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            let fishStats = cachedStats?.fishStatistics ?? []
            
            if !fishStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(fishStats.prefix(5)), id: \.0) { fish, count in
                        HStack {
                            Image(systemName: "fish.fill")
                                .foregroundColor(ThemeManager.primaryGreen)
                            Text(fish)
                                .font(.system(size: 16))
                            Spacer()
                            Text("\(count) time\(count == 1 ? "" : "s")")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text("No fish data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private var weatherStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weather Conditions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            let weatherStats = cachedStats?.weatherStatistics ?? []
            
            if !weatherStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(weatherStats.prefix(5)), id: \.0) { weather, count in
                        HStack {
                            Image(systemName: weatherIcon(for: weather))
                                .foregroundColor(ThemeManager.primaryBlue)
                            Text(weather)
                                .font(.system(size: 16))
                            Spacer()
                            Text("\(count) trip\(count == 1 ? "" : "s")")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Text("No weather data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    private func computeFishStatistics() -> [(String, Int)] {
        let allFish = trips.compactMap { $0.fishCaught }
            .flatMap { $0.components(separatedBy: ",") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let grouped = Dictionary(grouping: allFish) { $0 }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    private func computeWeatherStatistics() -> [(String, Int)] {
        let allWeather = trips.compactMap { $0.weatherCondition }
            .filter { !$0.isEmpty }
        
        let grouped = Dictionary(grouping: allWeather) { $0 }
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
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
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let expenses: Double
    let income: Double
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ComparisonRow: View {
    let year: String
    let amount: Double
    let color: Color
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        HStack {
            Text(year)
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            Text(currencyManager.format(amount))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

