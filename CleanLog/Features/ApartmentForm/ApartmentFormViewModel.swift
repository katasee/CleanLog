import Foundation
import Observation

@Observable @MainActor
final class ApartmentFormViewModel: Identifiable {
    private let repository: any ApartmentRepository
    private let apartment: Apartment?
    private let onAdd: (Apartment) -> Void
    private var isSaving = false

    var name: String {
        didSet { nameError = nil }
    }
    var priceText: String
    var accessCode: String
    var isReportedSeparately: Bool
    private(set) var nameError: String?
    private(set) var errorMessage: String?

    init(
        repository: any ApartmentRepository,
        editing apartment: Apartment?,
        suggestedName: String = "",
        locale: Locale = .current,
        onAdd: @escaping (Apartment) -> Void = { _ in }
    ) {
        self.repository = repository
        self.apartment = apartment
        self.onAdd = onAdd
        name = apartment?.name ?? suggestedName
        priceText = apartment.map { MoneyInput.string($0.price, locale: locale) } ?? ""
        accessCode = apartment?.accessCode ?? ""
        isReportedSeparately = apartment?.isReportedSeparately ?? false
    }

    var isAdding: Bool {
        apartment == nil
    }

    var canSave: Bool {
        !isSaving && draft != nil
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func save() async -> Bool {
        guard !isSaving, let draft else { return false }
        isSaving = true
        defer { isSaving = false }
        do {
            try await store(draft)
            return true
        } catch ApartmentError.duplicateName {
            nameError = String(localized: .apartmentsFormErrorDuplicateName)
        } catch {
            errorMessage = String(localized: .apartmentsFormErrorSave)
        }
        return false
    }

    private var draft: ApartmentDraft? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let price = MoneyInput.parse(priceText)
        else { return nil }
        return ApartmentDraft(
            name: name,
            price: price,
            accessCode: accessCode,
            isReportedSeparately: isReportedSeparately
        )
    }

    private func store(_ draft: ApartmentDraft) async throws {
        if let apartment {
            try await repository.update(apartment.applying(draft))
        } else {
            onAdd(try await repository.add(draft))
        }
    }
}
