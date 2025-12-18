import SwiftUI
import CoreData

struct TripsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FishingTrip.date, ascending: false)],
        animation: .default
    ) private var trips: FetchedResults<FishingTrip>
    
    @StateObject private var currencyManager = CurrencyManager.shared
    @State private var sortOption: SortOption = .date
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var showFilters = false
    
    enum SortOption: String, CaseIterable {
        case date = "Date"
        case profit = "Profit"
        case location = "Location"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case profitable = "Profitable"
        case loss = "Loss"
        case thisMonth = "This Month"
        case thisYear = "This Year"
    }
    
    var filteredAndSortedTrips: [FishingTrip] {
        var tripsArray = Array(trips)
        
        // Search filter
        if !searchText.isEmpty {
            tripsArray = tripsArray.filter { trip in
                trip.locationDisplayName.localizedCaseInsensitiveContains(searchText) ||
                (trip.note?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filter options
        switch filterOption {
        case .all:
            break
        case .profitable:
            tripsArray = tripsArray.filter { $0.netBalance > 0 }
        case .loss:
            tripsArray = tripsArray.filter { $0.netBalance < 0 }
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            tripsArray = tripsArray.filter { trip in
                guard let date = trip.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }
        case .thisYear:
            let calendar = Calendar.current
            let now = Date()
            tripsArray = tripsArray.filter { trip in
                guard let date = trip.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
        }
        
        // Sort
        switch sortOption {
        case .date:
            return tripsArray.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        case .profit:
            return tripsArray.sorted { $0.netBalance > $1.netBalance }
        case .location:
            return tripsArray.sorted { $0.locationDisplayName < $1.locationDisplayName }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if trips.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fish")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No trips yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Search bar
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(FilterOption.allCases, id: \.self) { option in
                                    FilterChip(
                                        title: option.rawValue,
                                        isSelected: filterOption == option
                                    ) {
                                        filterOption = option
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                        
                        // Sort picker
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        
                        // Results count
                        if !searchText.isEmpty || filterOption != .all {
                            HStack {
                                Text("\(filteredAndSortedTrips.count) trip\(filteredAndSortedTrips.count == 1 ? "" : "s") found")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                        
                        // Trips list
                        if filteredAndSortedTrips.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No trips found")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gray)
                                Text("Try adjusting your search or filters")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                        } else {
                            List {
                                ForEach(filteredAndSortedTrips, id: \.objectID) { trip in
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        TripRowView(trip: trip)
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("All Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchText.isEmpty || filterOption != .all {
                        Button("Clear") {
                            searchText = ""
                            filterOption = .all
                        }
                    }
                }
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search trips...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ThemeManager.primaryBlue : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    TripsListView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
