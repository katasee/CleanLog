import Foundation

nonisolated enum ApartmentError: Error, Equatable {
    case emptyName
    case duplicateName
    case negativePrice
    case notFound
}
