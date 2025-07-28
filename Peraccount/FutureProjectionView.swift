import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct FutureProjectionView: View {
  @State private var yearsToProject: Int = 1 // 예측할 년도
  @State private var projectedAmount: Double?
  @State private var isLoading: Bool = false
  @State private var errorMessage: String?
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("미래 자산 예측")
          .font(.largeTitle)
          .padding(.bottom, 20)
        
        Picker("예측 기간 (년)", selection: $yearsToProject) {
          ForEach(1...10, id: \.self) { year in
            Text("\(year)년 후").tag(year)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: yearsToProject) { _ in
          predictFutureAssets()
        }
        
        if isLoading {
          ProgressView("예측 중...")
        } else if let amount = projectedAmount {
          Text("\(yearsToProject)년 후 예상 자산:")
            .font(.headline)
          Text("\(amount, specifier: "%.0f")원")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.blue)
        } else if let error = errorMessage {
          Text("예측 오류: \(error)")
            .foregroundColor(.red)
        } else {
          Text("예측 기간을 선택해주세요.")
            .foregroundColor(.secondary)
        }
        
        Spacer()
      }
      .navigationTitle("미래 예측")
      .onAppear(perform: predictFutureAssets) // 초기 로드 시 예측
    }
  }
  
  func predictFutureAssets() {
    guard let userId = Auth.auth().currentUser?.uid else {
      self.errorMessage = "로그인이 필요합니다."
      return
    }
    
    isLoading = true
    errorMessage = nil
    projectedAmount = nil
    
    let functions = Functions.functions()
    functions.httpsCallable("predictFutureAssets").call(["userId": userId, "years": yearsToProject]) { (result, error) in
      isLoading = false
      // 여기에서 'error' 변수를 직접 사용합니다.
      if let nsError = error as NSError? { // error를 NSError로 캐스팅하여 nsError 변수에 할당
        if nsError.domain == FunctionsErrorDomain {
          let code = FunctionsErrorCode(rawValue: nsError.code)
          let message = nsError.localizedDescription
          print("Cloud Function 오류: \(code ?? .unknown) - \(message)")
          self.errorMessage = "예측 오류: \(message)"
        } else {
          self.errorMessage = "알 수 없는 오류 발생: \(nsError.localizedDescription)"
        }
      } else if error != nil { // NSError로 캐스팅 안되지만 nil이 아닌 경우 (덜 흔하지만 안전을 위해)
        self.errorMessage = "알 수 없는 오류 발생."
      }
      
      if let data = result?.data as? [String: Any],
         let predictedAmount = data["predictedAmount"] as? Double {
        self.projectedAmount = predictedAmount
      } else if self.errorMessage == nil { // 에러 메시지가 아직 설정되지 않았을 때만 설정
        self.errorMessage = "예측 결과를 받아오지 못했습니다."
      }
    }
  }
}
