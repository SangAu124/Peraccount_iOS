import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct MonthlySummaryView: View {
  @State private var selectedMonth = Date()
  @State private var summary: MonthlySummary?
  
  var body: some View {
    NavigationView {
      VStack {
        DatePicker(
          "월 선택",
          selection: $selectedMonth,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .padding()
        .onChange(of: selectedMonth) { _ in
          fetchMonthlySummary()
        }
        
        if let summary = summary {
          ScrollView {
            VStack(alignment: .leading, spacing: 15) {
              Text("총 수입: \(summary.totalIncome, specifier: "%.0f")원")
              Text("총 지출: \(summary.totalExpense, specifier: "%.0f")원")
              Text("총 저축/투자: \(summary.totalSavingInvestment, specifier: "%.0f")원")
              Text("순 잔액: \(summary.netBalance, specifier: "%.0f")원")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(summary.netBalance >= 0 ? .green : .red)
              
              // 파이 차트 (별도 뷰로 구현 필요)
              Text("비율 분석 (파이 차트 예정)")
                .font(.headline)
                .padding(.top)
              
              Text("주요 지출 카테고리 (예시)")
                .font(.headline)
                .padding(.top)
              // 실제로는 transactions에서 카테고리별로 집계하여 표시
              Text("식비: 500,000원")
              Text("교통비: 100,000원")
            }
            .padding()
          }
        } else {
          Text("선택된 월의 요약 데이터가 없습니다.")
            .foregroundColor(.secondary)
        }
      }
      .navigationTitle("월간 요약")
      .onAppear(perform: fetchMonthlySummary)
    }
  }
  
  func fetchMonthlySummary() {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    
    let currentYear = Calendar.current.component(.year, from: selectedMonth)
    let currentMonth = Calendar.current.component(.month, from: selectedMonth)
    
    db.collection("monthlySummaries").document("\(userId)-\(currentYear)-\(currentMonth)").getDocument { documentSnapshot, error in
      if let error = error {
        print("Error fetching monthly summary: \(error)")
        self.summary = nil
        return
      }
      if let document = documentSnapshot, document.exists {
        self.summary = try? document.data(as: MonthlySummary.self)
      } else {
        self.summary = nil
      }
    }
  }
}

// MonthlySummary 모델 (Codable을 사용하여 Firestore 데이터 매핑)
struct MonthlySummary: Identifiable, Codable {
  @DocumentID var id: String?
  let userId: String
  let year: Int
  let month: Int
  let totalIncome: Double
  let totalExpense: Double
  let totalSavingInvestment: Double
  let netBalance: Double
  let timestamp: Date
}
