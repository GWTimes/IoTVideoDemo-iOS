//
//  IVFoundation.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/2.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    func string(with encoding: String.Encoding) -> String? {
        return String(data: self, encoding: encoding)
    }
}

@propertyWrapper
struct Trimmed { //自动清除空格和换行 包装器
    private var value: String = ""
    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    init(wrappedValue initialValue: String) {
        self.wrappedValue = initialValue
    }
}

// 日期格式化
extension Date {
    func string(withFormat fmt: String = "yyyyMMdd-HH:mm:ss.SSS") -> String {
        let fmtr = DateFormatter()
        fmtr.dateFormat = fmt
        return fmtr.string(from: self)
    }
}



protocol IVPointer {
    var rawPointer: UnsafeRawPointer { get }
}

extension IVPointer where Self: Any {
    var rawPointer: UnsafeRawPointer {
        return unsafeBitCast(self, to: UnsafeRawPointer.self)
    }
}

extension IVPointer where Self: AnyObject {
    var rawPointer: UnsafeRawPointer {
        return UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }
}

extension NSObject: IVPointer {}

extension CGPoint: IVPointer {}
extension CGRect: IVPointer {}
extension CGSize: IVPointer {}
extension CGVector: IVPointer {}

#if os(iOS) || os(tvOS)
  extension UIEdgeInsets: IVPointer {}
  extension UIOffset: IVPointer {}
  extension UIRectEdge: IVPointer {}
#endif

extension Equatable where Self: Any {
    
    /// 是否等于给定序列的所有值
    ///
    ///     普通写法: if a == b && a == c && a == d { //true }
    ///     高级写法: if a.isEqual(allOf: b, c, d) { //true }
    /// - Parameter them: 要比较的参数序列
    /// - Returns: 是否等于
    public func isEqual(allOf them: Self...) -> Bool {
        for e in them {
            if e != self { return false }
        }
        return true
    }
    
    /// 是否等于给定序列的任意值
    ///
    ///     普通写法: if a == b || a == c || a == d { //true }
    ///     高级写法: if a.isEqual(oneOf: b, c, d) { //true }
    /// - Parameter them: 要比较的参数序列
    /// - Returns: 是否等于
    public func isEqual(oneOf them: Self...) -> Bool {
        for e in them {
            if e == self { return true }
        }
        return false
    }
}
