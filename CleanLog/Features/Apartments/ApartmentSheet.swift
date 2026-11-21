import Foundation

enum ApartmentSheet: Identifiable, Equatable {
    case new
    case edit(Apartment)

    var id: UUID? {
        apartment?.id
    }

    var apartment: Apartment? {
        switch self {
        case .new:
            nil
        case .edit(let apartment):
            apartment
        }
    }
}
