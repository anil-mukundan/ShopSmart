import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages = OnboardingPageData.all
    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Spacer()
                if !isLastPage {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.appAccent : Color.secondary.opacity(0.25))
                            .frame(width: index == currentPage ? 22 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.25), value: currentPage)
                    }
                }

                Button {
                    if isLastPage {
                        hasSeenOnboarding = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                } label: {
                    Text(isLastPage ? "Get Started" : "Next")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .tint(.appAccent)
                .controlSize(.large)
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
        }
    }
}

// MARK: - Page View

private struct OnboardingPageView: View {
    let page: OnboardingPageData

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: page.icon)
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                }
                .padding(.top, 40)

                Text(page.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 32)

                if !page.bullets.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(page.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appAccent)
                                Text(bullet)
                                    .font(.body)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Page Data

struct OnboardingPageData {
    let icon: String
    let title: String
    let body: String
    let bullets: [String]

    static let all: [OnboardingPageData] = [
        .init(
            icon: "cart.fill",
            title: "Welcome to ShopSmart",
            body: "ShopSmart makes grocery shopping effortless by organising your shopping lists around the stores you love. Getting started is easy:",
            bullets: [
                "Create your account",
                "Add the stores you shop at",
                "Build your master list of items",
                "Create shopping lists for each store",
                "Shop smarter, every time"
            ]
        ),
        .init(
            icon: "person.2.fill",
            title: "Shopping is Better Together",
            body: "Create your account with an email address and password. If you shop with a partner, family member, or friend — simply share your login details with them. Anyone signed in with the same account will see the same stores, items, and shopping lists in real time, making it easy for one person to plan and another to shop.",
            bullets: []
        ),
        .init(
            icon: "storefront.fill",
            title: "Add Your Favourite Stores",
            body: "Add the stores you regularly shop at to get started. You can include the store's name and location to keep things organised. Optionally, add the store's website URL — in a future release this will allow you to browse and purchase items directly from your shopping list without leaving the app.",
            bullets: []
        ),
        .init(
            icon: "list.bullet.clipboard.fill",
            title: "Build Your Master Item List",
            body: "Create a master list of everything you regularly buy. For each item you can specify which of your stores carry it, making it easy to build store-specific shopping lists later. You can also add optional details like preferred brand names or a photo of the product — handy when someone else is doing the shopping and needs to find the right item on the shelf.",
            bullets: []
        ),
        .init(
            icon: "checklist",
            title: "Smart Shopping Lists",
            body: "When you're ready to shop, create a list for a specific store and you'll only see items available at that store — no clutter, no confusion. As you use ShopSmart over time, the app learns which items you order most frequently from each store and puts them front and centre, so building your list gets faster every time.",
            bullets: []
        ),
        .init(
            icon: "figure.walk",
            title: "Shop Your Way",
            body: "Reorder items in your shopping list to match the layout of the store and the route you naturally take through it. Once you've set your preferred order, ShopSmart remembers it for future lists at that store — so you can move through the aisles efficiently every time, without backtracking.",
            bullets: []
        )
    ]
}

#Preview {
    OnboardingView()
}
