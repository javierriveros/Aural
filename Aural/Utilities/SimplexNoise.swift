import Foundation

enum SimplexNoise {
    // swiftlint:disable identifier_name
    private static let perm: [Int] = {
        let base = [
            151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225,
            140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148,
            247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32,
            57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175,
            74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122,
            60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54,
            65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
            200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64,
            52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212,
            207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213,
            119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
            129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104,
            218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241,
            81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157,
            184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93,
            222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
        ]
        return base + base
    }()

    private static let grad2: [(Double, Double)] = [
        (1, 1), (-1, 1), (1, -1), (-1, -1),
        (1, 0), (-1, 0), (0, 1), (0, -1)
    ]

    static func noise2D(x: Double, y: Double) -> Double {
        let f2 = 0.5 * (sqrt(3.0) - 1.0)
        let g2 = (3.0 - sqrt(3.0)) / 6.0

        let skewFactor = (x + y) * f2
        let skewedI = Int(floor(x + skewFactor))
        let skewedJ = Int(floor(y + skewFactor))

        let unskewFactor = Double(skewedI + skewedJ) * g2
        let originX = Double(skewedI) - unskewFactor
        let originY = Double(skewedJ) - unskewFactor

        let relX = x - originX
        let relY = y - originY

        let (offsetI, offsetJ): (Int, Int) = relX > relY ? (1, 0) : (0, 1)

        let corner1X = relX - Double(offsetI) + g2
        let corner1Y = relY - Double(offsetJ) + g2
        let corner2X = relX - 1.0 + 2.0 * g2
        let corner2Y = relY - 1.0 + 2.0 * g2

        let indexI = skewedI & 255
        let indexJ = skewedJ & 255

        let hash0 = perm[indexI + perm[indexJ]] % 8
        let hash1 = perm[indexI + offsetI + perm[indexJ + offsetJ]] % 8
        let hash2 = perm[indexI + 1 + perm[indexJ + 1]] % 8

        var contribution0 = 0.5 - relX * relX - relY * relY
        if contribution0 < 0 {
            contribution0 = 0
        } else {
            contribution0 *= contribution0
            contribution0 *= contribution0 * dot(grad2[hash0], relX, relY)
        }

        var contribution1 = 0.5 - corner1X * corner1X - corner1Y * corner1Y
        if contribution1 < 0 {
            contribution1 = 0
        } else {
            contribution1 *= contribution1
            contribution1 *= contribution1 * dot(grad2[hash1], corner1X, corner1Y)
        }

        var contribution2 = 0.5 - corner2X * corner2X - corner2Y * corner2Y
        if contribution2 < 0 {
            contribution2 = 0
        } else {
            contribution2 *= contribution2
            contribution2 *= contribution2 * dot(grad2[hash2], corner2X, corner2Y)
        }

        return 70.0 * (contribution0 + contribution1 + contribution2)
    }

    private static func dot(_ gradient: (Double, Double), _ x: Double, _ y: Double) -> Double {
        gradient.0 * x + gradient.1 * y
    }

    static func fbm(x: Double, y: Double, octaves: Int = 3, persistence: Double = 0.5) -> Double {
        var total = 0.0
        var frequency = 1.0
        var amplitude = 1.0
        var maxValue = 0.0

        for _ in 0..<octaves {
            total += noise2D(x: x * frequency, y: y * frequency) * amplitude
            maxValue += amplitude
            amplitude *= persistence
            frequency *= 2.0
        }

        return total / maxValue
    }
    // swiftlint:enable identifier_name
}
