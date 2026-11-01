import SwiftUI

struct AsyncStatusView: View {
    var isLoading = false
    var message: String?
    var retry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            if isLoading { ProgressView(FoundationL10n.loading) }
            if let message { Text(message).font(.body2).multilineTextAlignment(.center) }
            if let retry { Button(FoundationL10n.retry, action: retry).frame(minHeight: 44).accessibilityIdentifier("status.retry") }
        }.padding().frame(maxWidth: .infinity)
    }
}
