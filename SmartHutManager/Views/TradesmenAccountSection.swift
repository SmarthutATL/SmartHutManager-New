import SwiftUI

struct TradesmanAccountSection: View {
    let tradesman: Tradesmen?

    var body: some View {
        if let tradesman = tradesman {
            VStack(alignment: .leading, spacing: 12) {
                // Full Name
                Text(tradesman.name ?? "Unknown")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                // Job Title
                Text(tradesman.jobTitle ?? "Unknown Job Title")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)

                // Phone Number
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                    Text(tradesman.phoneNumber ?? "N/A")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                }

                // Address
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(tradesman.address ?? "N/A")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        } else {
            Text("No tradesman available")
                .foregroundColor(.gray)
                .font(.system(size: 16))
                .padding()
        }
    }
}
