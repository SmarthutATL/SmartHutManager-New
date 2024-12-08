import SwiftUI

struct RecentlyDeletedSection: View {
    @Binding var items: [DeletedItem]

    var body: some View {
        Section(header: Text("Recently Deleted")) {
            if items.isEmpty {
                Text("No recently deleted items")
                    .foregroundColor(.gray)
            } else {
                ForEach(items) { item in
                    HStack {
                        Image(systemName: item.icon)
                            .foregroundColor(item.type == .invoice ? .green : .blue)
                        Text(item.description)
                        Spacer()
                        Button(action: { restoreItem(item) }) {
                            Text("Restore").foregroundColor(.blue)
                        }
                        Button(action: { deleteItemPermanently(item) }) {
                            Text("Delete").foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    private func restoreItem(_ item: DeletedItem) {
        items.removeAll { $0.id == item.id }
    }

    private func deleteItemPermanently(_ item: DeletedItem) {
        items.removeAll { $0.id == item.id }
    }
}
