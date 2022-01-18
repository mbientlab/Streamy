import SwiftUI

extension Binding {

    /// If nil, close. If not nil, present the subject (i.e., error).
    ///
    func isPresented<O>() -> Binding<Bool> where Value == Optional<O> {
        Binding<Bool>(
            get: { !(self.wrappedValue == nil) },
            set: { _ in self.wrappedValue = nil }
        )
    }

    /// Change the subject.
    ///
    func isActive(_ target: Value) -> Binding<Bool> where Value: Equatable {
        Binding<Bool>(
            get: { self.wrappedValue == target },
            set: { if $0 { self.wrappedValue = target } }
        )
    }

    /// Requires mutability
    /// $state[dynamicMember: vm.choices].toggle(choice) with ReferenceWriteableKeyPath
    ///
    func toggle<E>(
        _ element: E, customSet: @escaping (Bool) -> Void
    ) -> Binding<Bool> where Value == Set<E> {
        .init { self.wrappedValue.contains(element) } set: { customSet($0) }
    }


    /// Requires mutability
    /// $state[dynamicMember: vm.choices].toggle(choice) with ReferenceWriteableKeyPath
    ///
    func toggle<E>(
        _ element: E
    ) -> Binding<Bool> where Value == Set<E> {

        .init {
            self.wrappedValue.contains(element)
        } set: { shouldUse in
            if shouldUse { self.wrappedValue.insert(element) }
            else { self.wrappedValue.remove(element) }
        }

    }
}
