import UIKit

enum Haptiek {
    static func licht() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
