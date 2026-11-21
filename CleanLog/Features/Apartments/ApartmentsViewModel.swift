import Foundation
import Observation

@Observable @MainActor
final class ApartmentsViewModel {
    private let repository: any ApartmentRepository
    private let locale: Locale
    private var apartments: [Apartment] = []
    private var hasLoaded = false

    private(set) var rows: [ApartmentRow] = []
    var sheet: ApartmentSheet?
    private(set) var pendingDeletion: ApartmentRow?
    private(set) var errorMessage: String?

    init(repository: any ApartmentRepository, locale: Locale = .current) {
        self.repository = repository
        self.locale = locale
    }

    var count: Int {
        rows.count
    }

    var showsEmptyState: Bool {
        hasLoaded && rows.isEmpty
    }

    var isConfirmingDeletion: Bool {
        get { pendingDeletion != nil }
        set { if !newValue { cancelDeletion() } }
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func observe() async {
        for await apartments in repository.apartments() {
            self.apartments = apartments
            rows = apartments.map { ApartmentRow($0, locale: locale) }
            hasLoaded = true
        }
    }

    func add() {
        sheet = .new
    }

    func edit(_ id: UUID) {
        guard let apartment = apartment(id) else { return }
        sheet = .edit(apartment)
    }

    func requestDeletion(_ id: UUID) {
        pendingDeletion = rows.first { $0.id == id }
    }

    func cancelDeletion() {
        pendingDeletion = nil
    }

    func confirmDeletion() async {
        guard let deletion = pendingDeletion else { return }
        pendingDeletion = nil
        do {
            try await repository.delete(deletion.id)
        } catch {
            errorMessage = String(localized: .apartmentsErrorDelete)
        }
    }

    private func apartment(_ id: UUID) -> Apartment? {
        apartments.first { $0.id == id }
    }
}
