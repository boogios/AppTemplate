//
//  Font+.swift
//  AppTemplate
//

import SwiftUI

extension Font {
    
    static let headline1 = Font.custom("Pretendard-Bold", size: 22)
    static let headline2 = Font.custom("Pretendard-Bold", size: 20)
    static let headline3 = Font.custom("Pretendard-Bold", size: 18)
    
    static let subtitle1 = Font.custom("Pretendard-SemiBold", size: 18)
    static let subtitle2 = Font.custom("Pretendard-SemiBold", size: 16)
    static let subtitle3 = Font.custom("Pretendard-SemiBold", size: 14)
    
    static let body1 = Font.custom("Pretendard-Regular", size: 16)
    static let body2 = Font.custom("Pretendard-Regular", size: 14)
    
    static let caption1 = Font.custom("Pretendard-Regular", size: 12)
    static let caption2 = Font.custom("Pretendard-Light", size: 12)
    
    static func pretendardBold(size: CGFloat) -> Font {
        return .custom("Pretendard-Bold", size: size)
    }
    
    static func pretendardSemiBold(size: CGFloat) -> Font {
        return .custom("Pretendard-SemiBold", size: size)
    }
    
    static func pretendardMedium(size: CGFloat) -> Font {
        return .custom("Pretendard-Medium", size: size)
    }
    
    static func pretendardRegular(size: CGFloat) -> Font {
        return .custom("Pretendard-Regular", size: size)
    }
    
    static func pretendardLight(size: CGFloat) -> Font {
        return .custom("Pretendard-Light", size: size)
    }
}
