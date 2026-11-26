import Foundation

enum ReportSendAction: Equatable {
    case whatsApp(URL)
    case share(String)
}
