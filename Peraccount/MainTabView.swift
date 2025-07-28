import SwiftUI

struct MainTabView: View {
  var body: some View {
    TabView {
      DashboardView()
        .tabItem { Label("대시보드", systemImage: "house.fill") }
      
      TransactionsView()
        .tabItem { Label("내역", systemImage: "list.bullet.rectangle.portrait.fill") }
      
      MonthlySummaryView()
        .tabItem { Label("월간 요약", systemImage: "chart.pie.fill") }
      
      FutureProjectionView()
        .tabItem { Label("미래 예측", systemImage: "chart.line.uptrend.xyaxis") }
      
      SettingsView() // 설정 탭 추가
        .tabItem { Label("설정", systemImage: "gearshape.fill") }
    }
  }
}
