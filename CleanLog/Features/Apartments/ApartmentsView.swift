import SwiftUI

struct ApartmentsView: View {
    var body: some View {
        NavigationStack {
            Color.background
                .ignoresSafeArea()
                .navigationTitle(Text(.tabApartmentsTitle))
        }
    }
}
