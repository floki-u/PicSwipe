import SwiftUI

struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack {
                Text("🌿").font(.system(size: 60))
                Text("PicSwipe").font(.largeTitle).fontWeight(.black)
                    .foregroundStyle(.white)
                Text("加载中...").foregroundStyle(Color.textSecondary)
            }
        }
    }
}
