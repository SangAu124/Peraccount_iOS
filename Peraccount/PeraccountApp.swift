// PeraccountApp.swift

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// AppDelegate를 사용하여 Firebase 초기화를 처리합니다.
// 이 코드가 없다면 App 구조체 init()에서 FirebaseApp.configure()를 호출합니다.
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("Firebase App configured via AppDelegate.")
    return true
  }
}

@main
struct PeraccountApp: App {
  // 앱 델리게이트 어댑터를 사용하여 AppDelegate를 연결합니다.
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  // 로그인 상태를 앱 전역에서 추적합니다.
  // AuthView, SettingsView에서 이 값을 업데이트하여 루트 뷰를 변경합니다.
  @AppStorage("isUserLoggedIn") var isUserLoggedIn: Bool = false
  
  // 온보딩 완료 여부를 앱 전역에서 추적합니다.
  // OnboardingView에서 이 값을 업데이트합니다.
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
  
  // Firebase Auth 리스너를 위한 상태 변수 (이 변수가 로그인 상태의 "진실의 원천"이 됩니다)
  @State private var firebaseAuthUser: FirebaseAuth.User?
  
  var body: some Scene {
    WindowGroup {
      Group {
        if firebaseAuthUser != nil {
          // 사용자가 Firebase Auth에 로그인된 상태
          if hasCompletedOnboarding {
            MainTabView() // 온보딩 완료 시 메인 탭 뷰
          } else {
            OnboardingView() // 온보딩 미완료 시 온보딩 뷰
          }
        } else {
          // 사용자 로그인 안 된 상태 (회원가입/로그인 필요)
          AuthView() // 로그인/회원가입 뷰
        }
      }
      // 앱 시작 시, 그리고 앱이 활성화될 때마다 Firebase Auth 상태를 감지합니다.
      .onAppear(perform: setupAuthListener)
    }
  }
  
  // Firebase Auth 상태 변화를 감지하는 리스너 설정
  private func setupAuthListener() {
    Auth.auth().addStateDidChangeListener { auth, user in
      DispatchQueue.main.async {
        self.firebaseAuthUser = user // Firebase Auth 사용자 객체를 직접 저장
        self.isUserLoggedIn = (user != nil) // @AppStorage도 업데이트하여 AuthView/SettingsView와 동기화
        
        print("Auth state changed. firebaseAuthUser is \(user != nil ? "present" : "nil").")
        print("isUserLoggedIn: \(self.isUserLoggedIn), hasCompletedOnboarding: \(self.hasCompletedOnboarding)")
        
        // 로그인했지만 온보딩 상태가 불일치할 경우 Firestore에서 확인 (선택 사항)
        if let user = user, !self.hasCompletedOnboarding {
          Task {
            await self.checkOnboardingStatusFromFirestore(userId: user.uid)
          }
        }
      }
    }
  }
  
  // Firestore에서 온보딩 상태를 확인하는 함수 (추가 일관성 확인용)
  private func checkOnboardingStatusFromFirestore(userId: String) async {
    let db = Firestore.firestore()
    do {
      let doc = try await db.collection("users").document(userId).getDocument()
      if let data = doc.data(), let onboardingCompletedInFirestore = data["onboardingCompleted"] as? Bool {
        if onboardingCompletedInFirestore != self.hasCompletedOnboarding {
          DispatchQueue.main.async {
            self.hasCompletedOnboarding = onboardingCompletedInFirestore
            print("Onboarding status updated from Firestore: \(self.hasCompletedOnboarding)")
          }
        }
      }
    } catch {
      print("Error checking onboarding status from Firestore: \(error.localizedDescription)")
    }
  }
}
