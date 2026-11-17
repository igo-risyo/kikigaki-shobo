import SwiftUI

/// ききがき書房 iPhone版。
/// 画面はサイト版と同じもの(Web フォルダの index.html)をアプリの中に入れて表示し、
/// 会話・学習・本の執筆は iPhone に入っている Apple の AI で動かす。
@main
struct KikigakiApp: App {
    var body: some Scene {
        WindowGroup {
            WebScreen()
                .background(Color(red: 0.984, green: 0.973, blue: 0.933))
                .ignoresSafeArea(.keyboard)
        }
    }
}
