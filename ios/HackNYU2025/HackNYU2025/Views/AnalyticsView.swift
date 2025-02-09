//
//  AnalyticsView.swift
//  HackNYU2025
//
//  Created by Alec Agayan on 2/9/25
//

import SwiftUI
import Charts

// A simple data model for monthly donation data.
struct DonationData: Identifiable {
    let id = UUID()
    let month: String
    let donationAmount: Double
}

struct AnalyticsView: View {
    // Sample static data; replace with your real analytics data.
    let month: String = "July 2023"
    let totalDonations: Double = 4500.00
    let donorCount: Int = 150
    let campaignCount: Int = 8

    // Sample donation history data.
    let donationHistory: [DonationData] = [
        DonationData(month: "Mar", donationAmount: 2000),
        DonationData(month: "Apr", donationAmount: 2500),
        DonationData(month: "May", donationAmount: 3000),
        DonationData(month: "Jun", donationAmount: 4000),
        DonationData(month: "Jul", donationAmount: 4500)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Main Monthly Summary Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(radius: 5)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Summary")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(month)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("$\(String(format: "%.2f", totalDonations))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        Text("Total Donations")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                .frame(height: 200)
                .padding(.horizontal)
                
                // MARK: - Monthly Donation History Graph
                VStack(alignment: .leading) {
                    Text("Donation History")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal)
                    
                    Chart {
                        ForEach(donationHistory) { data in
                            LineMark(
                                x: .value("Month", data.month),
                                y: .value("Donations", data.donationAmount)
                            )
                            .foregroundStyle(Color.accentColor)
                            .interpolationMethod(.catmullRom)
                            
                            // Optionally add data points.
                            PointMark(
                                x: .value("Month", data.month),
                                y: .value("Donations", data.donationAmount)
                            )
                            .foregroundStyle(Color.gray)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartYScale(domain: 0...((donationHistory.map { $0.donationAmount }.max() ?? 5000) * 1.1))
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                
                // MARK: - Sub Summary Cards
                HStack(spacing: 16) {
                    SubSummaryCardView(title: "Donors", value: "\(donorCount)")
                    SubSummaryCardView(title: "Campaigns", value: "\(campaignCount)")
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
    }
}

struct SubSummaryCardView: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.accentColor)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalyticsView()
        }
    }
}
