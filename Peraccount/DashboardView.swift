import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DashboardView: View {
  @State private var totalAssets: Double = 0.0
  @State private var currentMonthIncome: Double = 0.0
  @State private var currentMonthExpense: Double = 0.0
  @State private var currentMonthSavingInvestment: Double = 0.0
  @State private var remainingBalance: Double = 0.0
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("총 자산: \(totalAssets, specifier: "%.0f")원")
            .font(.title)
            .fontWeight(.bold)
            .padding(.bottom, 10)
          
          // 월간 재정 요약 카드
          VStack(alignment: .leading) {
            Text("이번 달 재정 요약")
              .font(.headline)
            HStack {
              StatCard(title: "수입", value: currentMonthIncome)
              StatCard(title: "지출", value: currentMonthExpense)
              StatCard(title: "저축/투자", value: currentMonthSavingInvestment)
            }
            Text("잔여 자금: \(remainingBalance, specifier: "%.0f")원")
              .font(.title2)
              .foregroundColor(.green)
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .cornerRadius(10)
          
          // 기타 그래프나 알림 추가 가능
        }
        .padding()
      }
      .navigationTitle("대시보드")
      .onAppear(perform: fetchData)
    }
  }
  
  func fetchData() {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    
    // 1. 현재 자산 불러오기
    db.collection("assets").document(userId).getDocument { documentSnapshot, error in
      if let document = documentSnapshot, document.exists {
        let data = document.data()
        self.totalAssets = (data?["cashBalance"] as? Double ?? 0.0) +
        (data?["investmentTotal"] as? Double ?? 0.0) +
        (data?["savingTotal"] as? Double ?? 0.0)
      }
    }
    
    // 2. 이번 달 월간 요약 불러오기
    let currentYear = Calendar.current.component(.year, from: Date())
    let currentMonth = Calendar.current.component(.month, from: Date())
    db.collection("monthlySummaries").document("\(userId)-\(currentYear)-\(currentMonth)").getDocument { documentSnapshot, error in
      if let document = documentSnapshot, document.exists {
        let data = document.data()
        self.currentMonthIncome = data?["totalIncome"] as? Double ?? 0.0
        self.currentMonthExpense = data?["totalExpense"] as? Double ?? 0.0
        self.currentMonthSavingInvestment = data?["totalSavingInvestment"] as? Double ?? 0.0
        self.remainingBalance = data?["netBalance"] as? Double ?? 0.0
      }
    }
  }
}

struct StatCard: View {
  let title: String
  let value: Double
  
  var body: some View {
    VStack {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text("\(value, specifier: "%.0f")원")
        .font(.subheadline)
        .fontWeight(.medium)
    }
    .padding(10)
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .cornerRadius(8)
    .shadow(radius: 1)
  }
}
