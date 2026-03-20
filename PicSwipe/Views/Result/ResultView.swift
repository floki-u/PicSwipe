import SwiftUI

struct ResultView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?
    let deletedCount: Int
    let freedSpace: Int64

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack {
                Text("已清理 \(deletedCount) 张").foregroundStyle(Color.brandPrimary)
                Text("释放 \(formatFileSize(freedSpace))").foregroundStyle(Color.textSecondary)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
