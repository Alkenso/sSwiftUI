//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#if os(macOS)

import AppKit

extension NSWindow {
    public var scAnimator: SCNSWindowAnimator { .init(window: self) }
}

public class SCNSWindowAnimator {
    private let window: NSWindow
    
    public init(window: NSWindow) {
        self.window = window
    }
    
    public func shake(number: Int = 3, duration: Double = 0.4, vigour: CGFloat = 0.04) {
        let frame = window.frame
        
        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))
        for _ in 0...(number - 1) {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigour, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigour, y: frame.minY))
        }
        shakePath.closeSubpath()
        
        let shakeAnimation = CAKeyframeAnimation()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = duration
        
        let animationsBackup = window.animations
        window.animations = ["frameOrigin": shakeAnimation]
        window.animator().setFrameOrigin(frame.origin)
        window.animations = animationsBackup
    }
}

#endif
