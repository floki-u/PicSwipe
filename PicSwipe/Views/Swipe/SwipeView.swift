import SwiftUI

struct SwipeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let mode: CleanMode

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("滑动浏览 - \(mode.rawValue)")
                .foregroundStyle(.white)
        }
        .navigationBarBackButtonHidden(true)
    }
}
