import SwiftUI

struct WatchItemDetailView: View {
    let entry: WatchEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                if let data = entry.imageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if let brand = entry.brand, !brand.isEmpty {
                    HStack {
                        Text("Brand")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(brand)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let notes = entry.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Note", systemImage: "text.bubble.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.caption2)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(entry.itemName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
