// SettingsView.swift

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
  // PeraccountApp의 @AppStorage 변수와 동일하게 선언하여 상태를 공유
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
  @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
  
  @State private var showingAlert: Bool = false
  @State private var alertTitle: String = ""
  @State private var alertMessage: String = ""
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("계정")) {
          Button("로그아웃") {
            Task {
              await signOutUser()
            }
          }
          .foregroundColor(.red)
        }
      }
      .navigationTitle("설정")
      .alert(alertTitle, isPresented: $showingAlert) {
        Button("확인") {}
      } message: {
        Text(alertMessage)
      }
    }
  }
  
  private func signOutUser() async {
    do {
      try Auth.auth().signOut()
      print("User signed out successfully.")
      
      DispatchQueue.main.async {
        // ✨ 핵심: 로그아웃 시 isUserLoggedIn 및 hasCompletedOnboarding 상태 초기화
        self.isUserLoggedIn = false
        self.hasCompletedOnboarding = false // 로그아웃 시 온보딩을 다시 하도록 강제
        
        self.alertTitle = "로그아웃 성공"
        self.alertMessage = "성공적으로 로그아웃되었습니다."
        self.showingAlert = true
      }
      
    } catch let signOutError as NSError {
      print("Error signing out: %@", signOutError)
      DispatchQueue.main.async {
        self.alertTitle = "로그아웃 실패"
        self.alertMessage = "로그아웃 중 오류가 발생했습니다: \(signOutError.localizedDescription)"
        self.showingAlert = true
      }
    }
  }
}
