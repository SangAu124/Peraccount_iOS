import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TransactionsView: View {
  @State private var showingAddTransactionSheet = false
  @State private var selectedMonth = Date()
  @State private var transactions: [Transaction] = []
  
  var body: some View {
    NavigationView {
      VStack {
        DatePicker(
          "월 선택",
          selection: $selectedMonth,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical) // 캘린더 모양으로 표시
        .padding()
        .onChange(of: selectedMonth) { _ in
          fetchTransactions()
        }
        
        List {
          ForEach(transactions) { transaction in
            HStack {
              Text(transaction.category)
              Spacer()
              Text("\(transaction.amount, specifier: "%.0f")원")
                .foregroundColor(transaction.type == "income" ? .blue : .red)
            }
          }
          .onDelete(perform: deleteTransaction)
        }
      }
      .navigationTitle("내역")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showingAddTransactionSheet = true
          } label: {
            Image(systemName: "plus.circle.fill")
          }
        }
      }
      .sheet(isPresented: $showingAddTransactionSheet) {
        AddTransactionView(isPresented: $showingAddTransactionSheet, onSave: fetchTransactions)
      }
      .onAppear(perform: fetchTransactions)
    }
  }
  
  func fetchTransactions() {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    
    let calendar = Calendar.current
    let year = calendar.component(.year, from: selectedMonth)
    let month = calendar.component(.month, from: selectedMonth)
    
    var components = DateComponents()
    components.year = year
    components.month = month
    let startDate = calendar.date(from: components)!
    
    components.month = month + 1
    components.day = 0 // 다음 달 0일 = 이번 달 마지막 날
    let endDate = calendar.date(from: components)!
    
    db.collection("transactions")
      .whereField("userId", isEqualTo: userId)
      .whereField("date", isGreaterThanOrEqualTo: startDate)
      .whereField("date", isLessThanOrEqualTo: endDate)
      .order(by: "date", descending: true)
      .getDocuments { (querySnapshot, error) in
        if let error = error {
          print("Error getting documents: \(error)")
          return
        }
        self.transactions = querySnapshot?.documents.compactMap { doc in
          try? doc.data(as: Transaction.self) // Codable 사용
        } ?? []
      }
  }
  
  func deleteTransaction(at offsets: IndexSet) {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    let db = Firestore.firestore()
    
    offsets.forEach { index in
      let transactionToDelete = transactions[index]
      if let id = transactionToDelete.id {
        db.collection("transactions").document(id).delete { error in
          if let error = error {
            print("Error removing document: \(error)")
          } else {
            print("Document successfully removed!")
            fetchTransactions() // 삭제 후 목록 새로고침
          }
        }
      }
    }
  }
}

// Transaction 모델 (Codable을 사용하여 Firestore 데이터 매핑)
struct Transaction: Identifiable, Codable {
  @DocumentID var id: String? // Firestore 문서 ID 자동 매핑
  let userId: String
  let type: String // "income" or "expense"
  let amount: Double
  let category: String
  let date: Date // Firestore Timestamp는 Date로 자동 변환
  let memo: String?
  let timestamp: Date // Firestore Timestamp
}

// 내역 추가 화면
struct AddTransactionView: View {
  @Binding var isPresented: Bool
  var onSave: () -> Void // 저장 후 호출될 클로저
  
  @State private var type: String = "expense"
  @State private var amount: String = ""
  @State private var category: String = "식비"
  @State private var date: Date = Date()
  @State private var memo: String = ""
  
  let categories = ["식비", "교통비", "문화생활", "구독료", "월급", "용돈", "기타"]
  
  var body: some View {
    NavigationView {
      Form {
        Picker("유형", selection: $type) {
          Text("지출").tag("expense")
          Text("수입").tag("income")
        }
        .pickerStyle(.segmented)
        
        TextField("금액", text: $amount)
          .keyboardType(.numberPad)
        
        Picker("카테고리", selection: $category) {
          ForEach(categories, id: \.self) { cat in
            Text(cat).tag(cat)
          }
        }
        
        DatePicker("날짜", selection: $date, displayedComponents: .date)
        
        TextField("메모 (선택 사항)", text: $memo)
        
        Button("저장") {
          saveTransaction()
        }
      }
      .navigationTitle("내역 추가")
      .navigationBarItems(leading: Button("취소") {
        isPresented = false
      })
    }
  }
  
  func saveTransaction() {
    guard let userId = Auth.auth().currentUser?.uid,
          let amountValue = Double(amount) else { return }
    
    let db = Firestore.firestore()
    db.collection("transactions").addDocument(data: [
      "userId": userId,
      "type": type,
      "amount": amountValue,
      "category": category,
      "date": date,
      "memo": memo,
      "timestamp": FieldValue.serverTimestamp()
    ]) { error in
      if let error = error {
        print("Error adding document: \(error)")
      } else {
        print("Document added successfully!")
        onSave() // 저장 후 목록 새로고침
        isPresented = false // 시트 닫기
      }
    }
  }
}
