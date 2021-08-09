//
//  IVApplication.swift
//  IotVideoDemoDev
//
//  Created by JonorZhang on 2020/6/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit

var gStatusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.size.height
}

var gOrientation: UIInterfaceOrientation {
    return UIApplication.shared.statusBarOrientation
}

var gIsLandscape: Bool {
    return gOrientation.isLandscape // .landscapeLeft || .landscapeRight
}

var gIsPortrait: Bool {
    return gOrientation.isPortrait // .portrait || .portraitUpsideDown
}

var kScreenWidth:  CGFloat {
    return UIScreen.main.bounds.width
}

var kScreenHeight: CGFloat {
    return UIScreen.main.bounds.height
}

/// iPhoneX、iPhoneXR、iPhoneXs、iPhoneXs Max等
/// 判断刘海屏，返回true表示是刘海屏
///
var gIsNotchScreen: Bool {
    
    if UIDevice.current.userInterfaceIdiom == .pad {
        return false
    }
    
    let size = UIScreen.main.bounds.size
    let notchValue: Int = Int(size.width/size.height * 100)
    
    if 216 == notchValue || 46 == notchValue {
        
        return true
    }
    
    return false
}
