// AuthView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore // Firestore 사용 시 필요

struct AuthView: View {
  @State private var email = ""
  @State private var password = ""
  @State private var errorMessage: String?
  @State private var isLoading = false
  
  // PeraccountApp의 @AppStorage 변수와 동일하게 선언하여 상태를 공유
  @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false // 필요시 온보딩 상태도 접근
  
  var body: some View {
    NavigationView {
      VStack {
        Text("Peraccountant")
          .font(.largeTitle)
          .padding(.bottom, 50)
        
        TextField("이메일", text: $email)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .autocapitalization(.none)
          .keyboardType(.emailAddress)
          .padding(.horizontal)
        
        SecureField("비밀번호", text: $password)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.horizontal)
          .padding(.bottom, 20)
        
        if isLoading {
          ProgressView()
        } else {
          Button("로그인") {
            Task { await signInUser() }
          }
          .buttonStyle(.borderedProminent)
          .padding(.bottom, 10)
          
          Button("회원가입") {
            Task { await registerUser() }
          }
          .buttonStyle(.bordered)
        }
        
        if let msg = errorMessage {
          Text(msg)
            .foregroundColor(.red)
            .padding(.top, 20)
        }
      }
      .navigationTitle("")
      .navigationBarHidden(true)
    }
    // AuthView는 isUserLoggedIn 값에 따라 자동으로 전환되므로 fullScreenCover는 불필요
  }
  
  // ✨ 비동기 로그인 함수
  private func signInUser() async {
    isLoading = true
    errorMessage = nil
    do {
      _ = try await Auth.auth().signIn(withEmail: email, password: password)
      print("User signed in successfully!")
      // 로그인 성공 시, PeraccountApp의 AuthStateDidChangeListener가 isUserLoggedIn을 true로 업데이트하고 화면 전환
    } catch {
      errorMessage = "로그인 실패: \(error.localizedDescription)"
      print("Login error: \(error.localizedDescription)")
    }
    isLoading = false
  }
  
  // ✨ 비동기 회원가입 함수
  private func registerUser() async {
    isLoading = true
    errorMessage = nil
    do {
      let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
      
      // ✨ 수정된 부분: authResult.user가 이미 User 타입이라고 가정
      let user = authResult.user // 에러 메시지에 따라 authResult.user는 이미 User 타입일 가능성이 높음
      let uid = user.uid // user.uid는 String 타입
      
      print("회원가입 성공: \(uid)")
      
      // 초기 사용자 정보 Firestore에 저장
      try await Firestore.firestore().collection("users").document(uid).setData([
        "email": email,
        "createdAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),
        "onboardingCompleted": false // 초기 회원가입 시 온보딩 미완료로 설정
      ])
      print("User document successfully written!")
      
      errorMessage = "회원가입 성공! 로그인되었습니다."
      
    } catch {
      errorMessage = "회원가입 실패: \(error.localizedDescription)"
      print("Registration error: \(error.localizedDescription)")
    }
    isLoading = false
  }
}
