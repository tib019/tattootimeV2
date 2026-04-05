import Foundation

struct PricingRule: Codable {
    var baseHourlyRate: Double = 120.0
    var depositPercentage: Double = 0.30

    // Multipliers per body part
    var bodyPart: [String: Double] = [
        "arm": 1.0, "leg": 1.0, "back": 1.3, "chest": 1.2,
        "ribs": 1.5, "neck": 1.4, "face": 2.0, "hand": 1.3, "foot": 1.3
    ]

    // Multipliers per style
    var style: [String: Double] = [
        "traditional": 1.0, "realistic": 1.4, "watercolor": 1.3,
        "geometric": 1.1, "minimalist": 0.9, "japanese": 1.2,
        "tribal": 1.0, "lettering": 0.8
    ]

    // Multipliers per complexity
    var complexity: [String: Double] = [
        "simple": 0.9, "medium": 1.0, "complex": 1.3, "very_complex": 1.6
    ]

    static let shared = PricingRule()

    func calculate(duration: Int, bodyPart: BodyPart, style: TattooStyle,
                   sizeArea: Double, complexity: Complexity) -> (total: Double, deposit: Double) {
        let hours = Double(duration) / 60.0
        let base = baseHourlyRate * hours

        let bm = self.bodyPart[bodyPart.rawValue] ?? 1.0
        let sm = self.style[style.rawValue] ?? 1.0
        let cm = self.complexity[complexity.rawValue] ?? 1.0
        let szm = sizeMultiplier(for: sizeArea)

        let total = (base * bm * sm * cm * szm * 100).rounded() / 100
        let deposit = (total * depositPercentage * 100).rounded() / 100
        return (total, deposit)
    }

    private func sizeMultiplier(for area: Double) -> Double {
        switch area {
        case ...25:   return 0.8
        case 26...100: return 1.0
        case 101...400: return 1.3
        default:      return 1.6
        }
    }
}
