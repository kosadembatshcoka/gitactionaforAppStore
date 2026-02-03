import SwiftUI
import CoreData
import UIKit

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)],
        animation: .default
    ) private var trips: FetchedResults<FishingTrip>
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var showNewTrip = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Statistics cards
                        statisticsSection
                        
                        // Recent trips
                        recentTripsSection
                    }
                    .padding()
                }
                
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showNewTrip = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(ThemeManager.primaryGreen)
                                .clipShape(Circle())
                                .shadow(color: ThemeManager.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showNewTrip) {
                TripFormView(trip: nil)
            }
        }
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            StatCard(
                title: "Total Spent This Year",
                value: currencyManager.format(totalSpentThisYear),
                color: ThemeManager.primaryBlue,
                icon: "arrow.down.circle.fill"
            )
            
            StatCard(
                title: "Earned from Selling Catch",
                value: currencyManager.format(totalEarnedThisYear),
                color: ThemeManager.primaryGreen,
                icon: "arrow.up.circle.fill"
            )
            
            StatCard(
                title: "Net Cost of Hobby",
                value: currencyManager.format(netCostThisYear),
                color: netCostThisYear >= 0 ? ThemeManager.primaryBlue : ThemeManager.primaryGreen,
                icon: "equal.circle.fill"
            )
            
            if let bestTrip = bestProfitTrip {
                StatCard(
                    title: "Best Trip Profit",
                    value: currencyManager.format(bestTrip.netBalance),
                    color: ThemeManager.primaryGreen,
                    icon: "star.fill"
                )
            }
        }
    }
    
    private var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Trips")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.horizontal, 4)
            
            if trips.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fish")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No trips yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.gray)
                    Text("Tap + to add your first fishing trip")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(Array(trips.prefix(5)), id: \.objectID) { trip in
                    NavigationLink(destination: TripDetailView(trip: trip)) {
                        TripRowView(trip: trip)
                    }
                }
            }
        }
    }
    
    // Computed properties
    private var totalSpentThisYear: Double {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        return trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.component(.year, from: date) == thisYear
            }
            .reduce(0) { $0 + $1.totalExpenses }
    }
    
    private var totalEarnedThisYear: Double {
        let calendar = Calendar.current
        let thisYear = calendar.component(.year, from: Date())
        return trips
            .filter { trip in
                guard let date = trip.date else { return false }
                return calendar.component(.year, from: date) == thisYear
            }
            .reduce(0) { $0 + $1.incomeFromSale }
    }
    
    private var netCostThisYear: Double {
        totalSpentThisYear - totalEarnedThisYear
    }
    
    private var bestProfitTrip: FishingTrip? {
        trips.max { ($0.netBalance) < ($1.netBalance) }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 60, height: 60)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct TripRowView: View {
    let trip: FishingTrip
    @StateObject private var currencyManager = CurrencyManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = trip.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ThemeManager.waterGradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "fish.fill")
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.locationDisplayName)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(trip.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(currencyManager.format(trip.netBalance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(trip.netBalance >= 0 ? ThemeManager.primaryGreen : .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

