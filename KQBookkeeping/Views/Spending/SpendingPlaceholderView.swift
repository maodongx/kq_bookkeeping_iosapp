import SwiftUI

struct SpendingPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "creditcard")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("记账功能")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("即将推出")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("记账")
        }
    }
}

#Preview {
    SpendingPlaceholderView()
}
