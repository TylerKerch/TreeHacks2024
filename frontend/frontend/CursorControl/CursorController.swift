import Cocoa

class CursorController {
    var matrix = CursorController.createMatrix()
    static func moveCursorToCenter() {
        if let screen = NSScreen.main {
            let center = CGPoint(x: screen.frame.midX, y: screen.frame.midY)
            CGWarpMouseCursorPosition(center)
        }
    }
    

    static func createMatrix() -> [[String]] {
        // Initialize an empty matrix for the default case
        var matrix: [[String]] = []
        
        if let screen = NSScreen.main {
            let screenWidth = Int(screen.frame.width)
            let screenHeight = Int(screen.frame.height)
            matrix = Array(repeating: Array(repeating: "", count: screenWidth), count: screenHeight)
        }
        
        return matrix
    }
    
    func addBoundingBox(x: Double, y: Double, height: Double, width: Double, id: String) {
        // Calculate the end points. Ensure they don't exceed the matrix bounds.
        let endX = min(Int(x + width), matrix[0].count - 1)
        let endY = min(Int(y + height), matrix.count - 1)
        
        // Loop through the specified range and add the id to each cell.
        for i in Int(x)...endX {
            for j in Int(y)...endY {
                matrix[j][i] = id
            }
        }
    }
}
