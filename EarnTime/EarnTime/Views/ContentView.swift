import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsViewModel
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var spendViewModel = SpendCreditsViewModel()
    @StateObject private var statsViewModel = StatsViewModel()

    var body: some View {
        TabView {
            HomeView(viewModel: homeViewModel, spendViewModel: spendViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            StatsView(viewModel: statsViewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .preferredColorScheme(settings.theme.colorScheme)
    }
}

private extension SettingsViewModel.ThemeOption {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
