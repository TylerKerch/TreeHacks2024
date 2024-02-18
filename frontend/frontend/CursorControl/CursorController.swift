import Cocoa

class CursorController {
    var matrix = CursorController.createMatrix()
    struct BoundingBox {
        var x: Double
        var y: Double
        var width: Double
        var height: Double
    }
    
    static func moveCursorToCenter() {
        if let screen = NSScreen.main {
            let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
            CGWarpMouseCursorPosition(center)
        }
    }
    

    static func createMatrix() -> [[BoundingBox?]] {
        // Initialize an empty matrix for the default case
        var matrix: [[BoundingBox?]] = []
        
        if let screen = NSScreen.main {
            let screenWidth = Int(screen.frame.width)
            let screenHeight = Int(screen.frame.height)
            matrix = Array(repeating: Array(repeating: nil, count: screenWidth), count: screenHeight)
        }
        
        return matrix
    }
    
    func addBoundingBox(x: Double, y: Double, height: Double, width: Double, id: String) {
        // Calculate the end points. Ensure they don't exceed the matrix bounds.
        let xInt = max(Int(x), 0)
        let yInt = max(Int(y), 0)
        let endX = min(xInt + Int(width), matrix[0].count - 1)
        let endY = min(yInt + Int(height), matrix.count - 1)
        // Loop through the specified range and add the id to each cell.

        for i in xInt...endX {
            for j in yInt...endY {
                matrix[j][i] = BoundingBox(x: x, y: y, width: width, height: height)
            }
        }
    }
    
    func returnHover(x: Int, y: Int) -> BoundingBox? {
        print("HELLO")
        print(y)
        print(x)
        print(matrix[y][x])
        return matrix[y][x]
    }
}
