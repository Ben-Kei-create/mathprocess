import SwiftUI

enum TKType {
    static let display    = Font.system(size: 36, weight: .semibold, design: .rounded)
    static let title      = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let subtitle   = Font.system(size: 18, weight: .medium,   design: .rounded)
    static let body       = Font.system(size: 16, weight: .regular,  design: .rounded)
    static let caption    = Font.system(size: 13, weight: .regular,  design: .rounded)

    /// Equation card font — slightly larger, monospaced digits.
    static let equation   = Font.system(size: 30, weight: .semibold, design: .rounded)
        .monospacedDigit()
}

enum TKSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}

enum TKRadius {
    static let small:  CGFloat = 8
    static let medium: CGFloat = 14
    static let large:  CGFloat = 22
}
