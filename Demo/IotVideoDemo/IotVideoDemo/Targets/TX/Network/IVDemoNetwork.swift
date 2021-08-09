//
//  IVDemoNetwork.swift
//  IotVideoDemoTX
//
//  Created by ZhaoYong on 2020/3/16.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo.IVNetConfig
import SwiftyJSON

public typealias IVDemoNetworkResponseHandler = ((_ data: Any?, _ error: Error?) -> Void)?

struct IVDemoNetwork {
    
    /// 云存套餐ID
    public static let cloudStoragePkgs = ["yc1m3d": "全时3天存储月套餐",
                                          "yc1m7d": "全时7天存储月套餐",
                                          "yc1m30d": "全时30天存储月套餐",
                                          "yc1y3d": "全时3天存储年套餐",
                                          "yc1y7d": "全时7天存储年套餐",
                                          "yc1y30d": "全时30天存储年套餐餐",
                                          "ye1m3d": "事件3天存储月套餐",
                                          "ye1m7d": "事件7天存储月套餐",
                                          "ye1m30d": "事件30天存储月套餐",
                                          "ye1y3d": "事件3天存储年套餐",
                                          "ye1y7d": "事件7天存储年套餐",
                                          "ye1y30d": "事件30天存储年套餐"]
    
    /// 绑定设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - role: 用户角色
    ///   - forceBind: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为owner时，可以不填
    ///   - responseHandler: 回调
    static func addDevice(_ deviceId: String, role: IVRole = .owner, forceBind: Bool = true, options: Any? = nil, responseHandler: IVDemoNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId) ?? ""
        IVTencentNetwork.shared.addDevice(accessId: accessId, deviceId: deviceId, role: role, forceBind: forceBind){ (json, error) in
            guard let json = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            
            //订阅设备 --- 绑定设备后，让IoTVideo快速加入此设备
            let succ = IVNetConfig.subscribeDevice(withAccessToken: json["Response"]["AccessToken"].stringValue, deviceId: deviceId)
            logDebug("subscribeDevice: ", succ)
            
            responseHandler?(true, nil)
        }
    }
    
    
    /// 解绑设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - role: 用户角色
    ///   - responseHandler: 回调
    static func deleteDevice(_ deviceId: String, role: IVRole, responseHandler: IVDemoNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId) ?? ""
        IVTencentNetwork.shared.deleteDevice(deviceId: deviceId, accessId: accessId, role: role) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            responseHandler?(true, error)
        }
    }
    
    /// 获取设备列表
    /// - Parameter responseHandler: 回调
    static func deviceList(responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.deviceList { (json, err) in
            guard let json = IVDemoNetwork.handlerError(json, err) else {
                responseHandler?(nil, err)
                return
            }
            
//            var newUserDeviceList: [IVDeviceModel] = [IVDeviceModel(devId: "429565449076740", deviceName: "测试", shareType: .guest)]
//            var newUserDeviceList: [IVDeviceModel] = [IVDeviceModel(devId: "031400005ebfdb9c56f0227d54544b8a", deviceName: "测试", shareType: .guest)]

            var newUserDeviceList: [IVDeviceModel] = []
            if let data = json["Response"]["Data"].array, !data.isEmpty {
                for device in data {
                    let deviceModel = IVDeviceModel(devId: device["Tid"].stringValue,
                                                    deviceName: device["DeviceName"].stringValue,
                                                    shareType: IVRole(rawValue: device["Role"].stringValue) ?? .owner)
                    newUserDeviceList.append(deviceModel)
                    
                    IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceModel.devId!, path: "ProReadonly._online") { (json, error) in
                        if let json = json {
                            deviceModel.online = JSON(parseJSON: json)["stVal"].intValue
                        }
                        responseHandler?(newUserDeviceList, nil)
                    }
                }
            } else {
                responseHandler?(newUserDeviceList, nil)
            }
        }
    }
    
    /// 获取设备绑定的用户列表
    ///
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - responseHandler: 回调
    static func getUserList(of deviceId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.getUserList(deviceId: deviceId){ (json, err) in
            guard let json = IVDemoNetwork.handlerError(json, err) else {
                responseHandler?(nil, err)
                return
            }
            let data = json["Response"]["Data"]
                .arrayValue
                .filter{$0["Role"].stringValue == IVRole.guest.rawValue}
                .map{$0["AccessId"].stringValue}
            responseHandler?(data, nil)
        }
    }
    
    
    
    /// 分享设备
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - accessId: 接受者的accessid
    ///   - responseHandler: 回调
    /// 此接口尽量由分享者自己去调用，然后订阅设备（即主人根据分享者账号，分享，分享者同意分享操作后调用此接口）
    /// demo内为设备主人调用然后分享者重新登录完成分享操作
    static func shareDevice(_ deviceId: String, to accessId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.addDevice(accessId: accessId, deviceId: deviceId, role: .guest, forceBind: false){ (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            //这里没有调用订阅，是因为订阅需要分享者自己去调用
            responseHandler?(true, nil)
        }
    }
    
    /// 取消分享
    /// - Parameters:
    ///   - deviceId: 设备id
    ///   - accessId: 用户id
    ///   - role: accessId的用户角色
    ///   - responseHandler: 回调
    static func cancelSharing(_ deviceId: String, accessId: String, role: IVRole, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.deleteDevice(deviceId: deviceId, accessId: accessId, role: role) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            responseHandler?(true, error)
        }
    }
    
 
    static func queryBuyedCloudStoragePackage(serviceId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.queryBuyedCloudStoragePackage(serviceId: serviceId) { (json, error) in
            guard let resJson = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
           
            if let data = resJson["Data"].array, let pkg = data.first(where: {$0["Status"].intValue == 1}) {
                let res = ["pkgName": cloudStoragePkgs[pkg["PkgId"].stringValue],
                           "startTime": "\(pkg["StartTime"].intValue)",
                           "endTime": "\(pkg["EndTime"].intValue)"]
                responseHandler?(res, nil)
            } else {
                responseHandler?(nil, error)
            }
            
            responseHandler?(resJson, error)
        }
    }
    
    static func buyCloudStoragePackage(_ packageID: String, deviceId: String, responseHandler: IVDemoNetworkResponseHandler) {
        IVTencentNetwork.shared.buyCloudStoragePackage(packageID: packageID, deviceId: deviceId) { (json, error) in
            guard let _ = IVDemoNetwork.handlerError(json, error) else {
                responseHandler?(nil, error)
                return
            }
            logInfo(json as Any)
            
            responseHandler?(true, error)
        }
    }
}

extension IVDemoNetwork {
    
    static func handlerError(_ json: String?,_ error: Error?) -> JSON? {
        
        if let error = error {
            showError(error)
            return nil
        }
        
        let json = JSON(parseJSON: json!)
        if let errorCode = json["Response"]["Error"]["Code"].string {
            let errMsg = "\(errorCode) : \(json["Response"]["Error"]["Message"].stringValue)"
            logError(errMsg)
            ivHud(errMsg)
            return nil
        }
        return json
    }
}


