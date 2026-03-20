import SwiftUI

struct ConfirmDeleteView: View {
    @Binding var path: NavigationPath
    @Binding var cleanSession: CleanSession?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("确认删除").foregroundStyle(.white)
        }
        .navigationBarBackButtonHidden(true)
    }
}
