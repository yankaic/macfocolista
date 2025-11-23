import SwiftUI

struct CopyReferenceKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var onCopyReference: (() -> Void)? {
        get { self[CopyReferenceKey.self] }
        set { self[CopyReferenceKey.self] = newValue }
    }
}
