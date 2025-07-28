import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingView: View {
  @State private var currentStep: Int = 0
  
  @State private var cashBalance: String = ""
  @State private var investmentTotal: String = ""
  @State private var savingTotal: String = ""
  @State private var monthlyIncomeItems: [IncomeItem] = [IncomeItem(name: "월급", amount: "")]
  @State private var monthlyFixedExpenseItems: [ExpenseItem] = [ExpenseItem(name: "구독료", amount: "")]
  
  // 온보딩 완료 여부는 PeraccountApp과 동기화
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
  
  @State private var isProcessingStep: Bool = false // ✨ 핵심: 저장 중임을 나타내는 상태 변수
  @State private var showingAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  
  var body: some View {
    VStack {
      Text("온보딩 \(currentStep + 1)/3")
        .font(.headline)
        .padding()
      
      if currentStep == 0 {
        InitialAssetsInputView(cashBalance: $cashBalance, investmentTotal: $investmentTotal, savingTotal: $savingTotal)
      } else if currentStep == 1 {
        MonthlyIncomeInputView(incomeItems: $monthlyIncomeItems)
      } else if currentStep == 2 {
        MonthlyFixedExpenseInputView(expenseItems: $monthlyFixedExpenseItems)
      }
      
      Spacer()
      
      HStack {
        if currentStep > 0 {
          Button("이전") {
            currentStep -= 1
          }
          .buttonStyle(.bordered)
          .disabled(isProcessingStep) // 처리 중 비활성화
        }
        Spacer()
        Button(currentStep == 2 ? "시작하기" : "다음") {
          // 비동기 함수 호출
          Task {
            await saveDataAndProceed()
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isProcessingStep) // ✨ 핵심: 처리 중 비활성화
      }
      .padding()
    }
    .alert(alertTitle, isPresented: $showingAlert) {
      Button("확인") {}
    } message: {
      Text(alertMessage)
    }
  }
  
  // ✨ 비동기 저장 함수로 변경
  private func saveDataAndProceed() async {
    guard let userId = Auth.auth().currentUser?.uid else {
      presentAlert(title: "인증 오류", message: "로그인이 필요합니다. 앱을 다시 시작해주세요.")
      return
    }
    
    isProcessingStep = true // 처리 시작
    let db = Firestore.firestore()
    
    do {
      if currentStep == 0 {
        try await db.collection("assets").document(userId).setData([
          "userId": userId,
          "cashBalance": Double(cashBalance) ?? 0.0,
          "investmentTotal": Double(investmentTotal) ?? 0.0,
          "savingTotal": Double(savingTotal) ?? 0.0,
          "lastUpdated": FieldValue.serverTimestamp()
        ])
        print("Assets saved!")
        
      } else if currentStep == 1 {
        let totalMonthlyIncome = monthlyIncomeItems.reduce(0.0) { $0 + (Double($1.amount) ?? 0.0) }
        try await db.collection("users").document(userId).updateData([
          "monthlyIncomeItems": monthlyIncomeItems.map { ["name": $0.name, "amount": Double($0.amount) ?? 0.0] },
          "totalMonthlyIncome": totalMonthlyIncome
        ])
        print("Income saved!")
        
      } else if currentStep == 2 {
        let totalFixedExpense = monthlyFixedExpenseItems.reduce(0.0) { $0 + (Double($1.amount) ?? 0.0) }
        try await db.collection("users").document(userId).updateData([
          "monthlyFixedExpenseItems": monthlyFixedExpenseItems.map { ["name": $0.name, "amount": Double($0.amount) ?? 0.0] },
          "totalFixedExpense": totalFixedExpense,
          "onboardingCompleted": true // 온보딩 완료 상태를 Firestore에 저장
        ])
        print("Fixed expenses saved!")
        
        // Firestore 저장 완료 후 @AppStorage 업데이트
        // PeraccountApp의 AuthStateDidChangeListener가 이 값을 감지하여 화면 전환을 트리거할 것임.
        DispatchQueue.main.async {
          hasCompletedOnboarding = true
          print("Onboarding completed: hasCompletedOnboarding set to true in @AppStorage")
        }
      }
      
      // 현재 단계의 저장 작업이 성공적으로 완료된 후에만 다음 단계로 이동
      if currentStep < 2 {
        currentStep += 1
      }
      
    } catch {
      print("Error saving data for step \(currentStep): \(error.localizedDescription)")
      presentAlert(title: "저장 오류", message: "데이터 저장 중 오류가 발생했습니다: \(error.localizedDescription)")
    }
    
    isProcessingStep = false // 처리 완료
  }
  
  private func presentAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    showingAlert = true
  }
}

// 온보딩 단계별 서브 뷰 (예시)
struct InitialAssetsInputView: View {
  @Binding var cashBalance: String
  @Binding var investmentTotal: String
  @Binding var savingTotal: String
  
  var body: some View {
    VStack {
      Text("현재 자산을 입력해주세요.")
        .font(.title2)
        .padding(.bottom, 20)
      TextField("현금성 자산 (예: 1000000)", text: $cashBalance)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.numberPad)
        .padding(.horizontal)
      TextField("투자 자산 (예: 500000)", text: $investmentTotal)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.numberPad)
        .padding(.horizontal)
      TextField("저축성 자산 (예: 200000)", text: $savingTotal)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .keyboardType(.numberPad)
        .padding(.horizontal)
    }
  }
}

struct IncomeItem: Identifiable {
  let id = UUID()
  var name: String
  var amount: String
}

struct MonthlyIncomeInputView: View {
  @Binding var incomeItems: [IncomeItem]
  
  var body: some View {
    VStack {
      Text("월간 수입을 입력해주세요.")
        .font(.title2)
        .padding(.bottom, 20)
      ForEach($incomeItems) { $item in
        HStack {
          TextField("수입 항목 (예: 월급)", text: $item.name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          TextField("금액", text: $item.amount)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
        }
        .padding(.horizontal)
      }
      Button("수입 항목 추가") {
        incomeItems.append(IncomeItem(name: "", amount: ""))
      }
    }
  }
}

struct ExpenseItem: Identifiable {
  let id = UUID()
  var name: String
  var amount: String
}

struct MonthlyFixedExpenseInputView: View {
  @Binding var expenseItems: [ExpenseItem]
  
  var body: some View {
    VStack {
      Text("월간 고정 지출을 입력해주세요.")
        .font(.title2)
        .padding(.bottom, 20)
      ForEach($expenseItems) { $item in
        HStack {
          TextField("지출 항목 (예: 구독료)", text: $item.name)
            .textFieldStyle(RoundedBorderTextFieldStyle())
          TextField("금액", text: $item.amount)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.numberPad)
        }
        .padding(.horizontal)
      }
      Button("지출 항목 추가") {
        expenseItems.append(ExpenseItem(name: "", amount: ""))
      }
    }
  }
}
