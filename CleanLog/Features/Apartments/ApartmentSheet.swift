import Foundation

enum ApartmentSheet: Identifiable, Equatable {
    case new
    case edit(Apartment)

    var id: UUID? {
        switch self {
        case .new:
            nil
        case .edit(let apartment):
            apartment.id
        }
    }
}
