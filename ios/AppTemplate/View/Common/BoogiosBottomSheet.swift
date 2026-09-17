//
//  BoogiosBottomSheet.swift
//  AppTemplate
//

import SwiftUI

struct BoogiosBottomSheet<Content: View>: View {
    
    @Binding var isPresented: Bool
    var horizontalPadding: CGFloat = 20
    let content: () -> Content
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.boogiosGray3)
                        .frame(width: 32, height: 3)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    
                    content()
                }
                .frame(maxWidth: .infinity)
                .background(Color.boogiosWhite)
                .cornerRadius(20)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}
