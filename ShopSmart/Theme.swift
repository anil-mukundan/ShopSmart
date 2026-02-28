import SwiftUI
import UIKit

extension Color {
    /// Soft cornflower blue — app-wide accent colour.
    static let appAccent = Color(red: 0.32, green: 0.59, blue: 0.92)
}

/// Returns true if two item names are the same or likely plural/singular variants.
/// Handles: exact (case-insensitive), +s, +es, and y→ies endings.
func isSimilarItemName(_ a: String, _ b: String) -> Bool {
    let x = a.lowercased().trimmingCharacters(in: .whitespaces)
    let y = b.lowercased().trimmingCharacters(in: .whitespaces)
    if x == y { return true }
    let (shorter, longer) = x.count <= y.count ? (x, y) : (y, x)
    if longer.hasPrefix(shorter) {
        let suffix = longer.dropFirst(shorter.count)
        if suffix == "s" || suffix == "es" { return true }
    }
    // y → ies: "berry" / "berries", "cherry" / "cherries"
    let xBase = x.hasSuffix("ies") ? String(x.dropLast(3)) : (x.hasSuffix("y") ? String(x.dropLast()) : nil)
    let yBase = y.hasSuffix("ies") ? String(y.dropLast(3)) : (y.hasSuffix("y") ? String(y.dropLast()) : nil)
    if let xb = xBase, let yb = yBase { return xb == yb }
    return false
}

// MARK: - Store Logo

/// Builds a DuckDuckGo favicon URL from a store website URL string.
/// Strips www. and scheme so the service gets a bare domain like "target.com".
private func faviconURL(for websiteURL: String) -> URL? {
    var s = websiteURL.trimmingCharacters(in: .whitespaces)
    if !s.hasPrefix("http://") && !s.hasPrefix("https://") { s = "https://" + s }
    guard var host = URL(string: s)?.host else { return nil }
    if host.hasPrefix("www.") { host = String(host.dropFirst(4)) }
    return URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico")
}

/// Shows a store's favicon with a spinner while loading.
/// Falls back to a generic storefront badge if no URL is set or the fetch fails.
struct StoreLogo: View {
    let store: StoreModel
    var size: CGFloat = 34

    @State private var logo: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        Group {
            if let logo {
                Image(uiImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.26))
            } else if isLoading {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.26)
                        .fill(Color.appAccent.opacity(0.1))
                        .frame(width: size, height: size)
                    ProgressView()
                        .scaleEffect(size / 44)
                }
            } else {
                IconBadge(systemName: "storefront.fill", size: size)
            }
        }
        .task(id: store.websiteURL) {
            logo = nil
            guard let websiteURL = store.websiteURL,
                  let url = faviconURL(for: websiteURL) else { return }
            isLoading = true
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                logo = image
            }
            isLoading = false
        }
    }
}

// MARK: - UIImage helpers

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(size.width, size.height)
        guard scale < 1 else { return self }
        let newSize = CGSize(width: (size.width * scale).rounded(),
                             height: (size.height * scale).rounded())
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

/// Rounded-square icon badge used in list rows.
struct IconBadge: View {
    let systemName: String
    var color: Color = .appAccent
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Image(systemName: systemName)
                .font(.system(size: size * 0.46, weight: .medium))
                .foregroundStyle(color)
        }
    }
}
