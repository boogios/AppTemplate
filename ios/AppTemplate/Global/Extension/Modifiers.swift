//
//  Modifiers.swift
//  AppTemplate
//

import SwiftUI

private struct BoogiosToastModifier: ViewModifier {
    
    @Binding var isPresented: Bool
    let message: String
    let bottomPadding: CGFloat
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            
            if isPresented {
                BoogiosToastView(message: message)
                    .padding(.bottom, bottomPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    
    func boogiosToast(isPresented: Binding<Bool>, message: String, bottomPadding: CGFloat = 40) -> some View {
        modifier(BoogiosToastModifier(isPresented: isPresented, message: message, bottomPadding: bottomPadding))
    }
}
