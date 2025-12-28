//
//  NutritionStatsView.swift
//  NutriVision
//
//  Created by Vasco Zambujo on 26/12/2025.
//

import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth

enum TimeSpan: String, CaseIterable {
    case daily = "Daily", weekly = "Weekly", monthly = "Monthly"
    var days: Int {
        switch self { case .daily: return 7; case .weekly: return 28; case .monthly: return 90 }
    }
}

enum MacroType: String, CaseIterable {
    case calories = "Calories", protein = "Protein", carbs = "Carbs", fats = "Fats"
    var unit: String { self == .calories ? "kcal" : "g" }
    var icon: String {
        switch self {
        case .calories: return "flame.fill"; case .protein: return "leaf.fill"
        case .carbs: return "bolt.fill"; case .fats: return "drop.fill"
        }
    }
    var color: Color {
        switch self {
        case .calories: return .orange; case .protein: return .blue
        case .carbs: return .green; case .fats: return .red
        }
    }
}

struct TimeSpanButton: View {
    let timeSpan: TimeSpan
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(timeSpan.rawValue)
                .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.blue : (colorScheme == .light ? Color.white : Color.white.opacity(0.1)))
                        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 5)
                )
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Data Yet")
                .font(.headline)
            
            Text("Log some meals to see your progress here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
}

struct NutritionData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct NutritionStatsView: View {
    @StateObject private var vm = NutritionViewModel()
    @State private var selectedTimeSpan: TimeSpan = .daily
    @State private var selectedMacro: MacroType = .calories
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                
                // 1. Time Period Selector
                VStack(spacing: 12) {
                    Text("Time Period")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        ForEach(TimeSpan.allCases, id: \.self) { span in
                            TimeSpanButton(
                                timeSpan: span,
                                isSelected: selectedTimeSpan == span
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTimeSpan = span
                                    vm.fetchData(for: selectedTimeSpan, macro: selectedMacro)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // 2. Nutrient Type Grid
                VStack(spacing: 12) {
                    Text("Nutrient Type")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(MacroType.allCases, id: \.self) { macro in
                            MacroTypeButton(
                                macroType: macro,
                                isSelected: selectedMacro == macro
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedMacro = macro
                                    vm.fetchData(for: selectedTimeSpan, macro: selectedMacro)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 3. Summary Cards
                HStack(spacing: 12) {
                    SummaryCard(
                        title: "Avg",
                        value: String(format: "%.0f", vm.averageValue),
                        unit: selectedMacro.unit,
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    SummaryCard(
                        title: "Total",
                        value: String(format: "%.0f", vm.totalValue),
                        unit: selectedMacro.unit,
                        icon: "sum",
                        color: .green
                    )
                    
                    SummaryCard(
                        title: "Max",
                        value: String(format: "%.0f", vm.highestValue),
                        unit: selectedMacro.unit,
                        icon: "arrow.up.circle.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)

                // 4. Chart Section
                VStack {
                    if vm.isLoading {
                        ProgressView()
                            .frame(height: 300)
                    } else if vm.nutritionData.isEmpty {
                        EmptyStateView()
                    } else {
                        ChartView(
                            data: vm.nutritionData,
                            macroType: selectedMacro,
                            timeSpan: selectedTimeSpan
                        )
                        .frame(height: 300)
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
            }
        }
        .background(Color(colorScheme == .light ? .systemGroupedBackground : .black))
        .navigationTitle("Nutrition Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            vm.fetchData(for: selectedTimeSpan, macro: selectedMacro)
        }
    }
}

struct MacroTypeButton: View {
    let macroType: MacroType; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(macroType.rawValue, systemImage: macroType.icon)
                .frame(maxWidth: .infinity).padding().background(isSelected ? macroType.color : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary).cornerRadius(10)
        }
    }
}

struct SummaryCard: View {
    let title, value, unit, icon: String; let color: Color
    var body: some View {
        VStack {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value).font(.headline) + Text(" " + unit).font(.caption2)
        }.frame(maxWidth: .infinity).padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
    }
}

struct ChartView: View {
    let data: [NutritionData]; let macroType: MacroType; let timeSpan: TimeSpan
    var body: some View {
        Chart(data) {
            LineMark(
                x: .value("Day", $0.date),
                y: .value("Val", $0.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(macroType.color)
            
            AreaMark(
                x: .value("Day", $0.date),
                y: .value("Val", $0.value)
            )
            .foregroundStyle(macroType.color.opacity(0.1))
            
            PointMark(
                x: .value("Day", $0.date),
                y: .value("Val", $0.value)
            )
            .foregroundStyle(macroType.color)
        }
        .chartYScale(domain: 0...max((data.map { $0.value }.max() ?? 100) * 1.2, 100))
        .padding(.bottom, 20)
    }
}
