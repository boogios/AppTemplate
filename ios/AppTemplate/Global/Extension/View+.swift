//
//  View+.swift
//  AppTemplate
//

import SwiftUI
import UIKit

extension View {
    
    func customNavigationBar(title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
    
    func boogiosCardStyle(cornerRadius: CGFloat = 16) -> some View {
        padding(20)
            .background(Color.boogiosWhite)
            .cornerRadius(cornerRadius)
    }
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
