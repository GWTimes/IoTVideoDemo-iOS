//
//  IVTencentNetworkAPI.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/3/11.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo
import SwiftyJSON


//具体API请求
extension IVTencentNetwork {
    //注册
//    func register(tmpSecretID: String, tmpSecretKey: String, token: String, userName: String, responseHandler: IVTencentNetworkResponseHandler) {
//        IVTencentNetwork.shared.secretKey = tmpSecretKey
//        IVTencentNetwork.shared.secretId = tmpSecretID
//        IVTencentNetwork.shared.token = token
//        
//        UserDefaults.standard.do {
//            $0.setValue(tmpSecretID, forKey: demo_secretId)
//            $0.setValue(tmpSecretKey, forKey: demo_secretKey)
//            $0.setValue(token, forKey: demo_loginToken)
//        }
//        
//        IVTencentNetwork.shared.token = token
//        self.request(methodType: .POST,
//                     action: "CreateAppUsr",
//                     params: ["CunionId": userName],
//                     response: responseHandler)
//    }
    
    func register(account: TXAccount, responseHandler: IVTencentNetworkResponseHandler) {
        IVTencentNetwork.shared.secretKey = account.secretKey
        IVTencentNetwork.shared.secretId = account.secretId
        IVTencentNetwork.shared.token = account.tempToken
        
        UserDefaults.standard.do {
            $0.setValue(account.secretId, forKey: demo_secretId)
            $0.setValue(account.secretKey, forKey: demo_secretKey)
            $0.setValue(account.tempToken, forKey: demo_loginToken)
        }
        self.request(methodType: .POST,
                     action: "CreateAppUsr",
                     params: ["CunionId": account.userName],
                     response: responseHandler)
    }
    
    //登录
    func login(accessId: String, responseHandler:IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "CreateUsrToken",
                     params: ["AccessId": accessId,
                              "UniqueId": IVTencentNetwork.shared.getUniqueId(),
                              "TtlMinutes": 43200],
                     response: responseHandler)
    }
    
    // 匿名登录
    // 首次登录 tid 必填
    // 续租token, oldAccessToken 必填
    func AnonymousLogin(tid: String?, oldAccessToken: String?, ttlMinutes: Int = 1440,responseHandler:IVTencentNetworkResponseHandler)  {
        var ttl = 1440
        if ttlMinutes > 1440 {
            ttl = 1440
        }
        if ttlMinutes < 1 {
            ttl = 1
        }
        
        var params = [String: Any]()
        if tid != nil {
            params["Tid"] = tid!
        }
        if oldAccessToken != nil {
            params["OldAccessToken"] = oldAccessToken
        }
        params["TtlMinutes"] = ttl
        
        self.request(methodType: .POST,
                     action: "CreateAnonymousAccessToken",
                     params: params,
                     response: responseHandler)
    }
    
    //获取设备列表
    func deviceList(responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.string(forKey: demo_accessId) ?? ""
        self.request(methodType: .POST,
                     action: "DescribeBindDev",
                     params: ["AccessId": accessId],
                     response: responseHandler)
    }
    
    //绑定设备
    //role: .owner 主人绑定设备
    //role: .guest 绑定别人分享的设备
    //forceBid: 默认true 是否踢掉之前的主人，true：踢掉；false：不踢掉。当role为guest时，可以不填
    func addDevice(accessId: String, deviceId: String, role: IVRole, forceBind: Bool = true, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "CreateBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue,
                              "ForceBind": forceBind],
                     response: responseHandler)
    }
    
    //解绑
    func deleteDevice(deviceId: String, accessId: String, role: IVRole, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "DeleteBinding",
                     params: ["AccessId": accessId,
                              "Tid": deviceId,
                              "Role": role.rawValue],
                     response: responseHandler)
    }
    
    //获取设备绑定的用户列表
    func getUserList(deviceId: String, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "DescribeBindUsr",
                     params: ["Tid": deviceId],
                     response: responseHandler)
    }
    
    /// 临时访问
    /// 终端用户与设备没有强绑定关联关系; 允许终端用户短时或一次性临时访问设备; 当终端用户与设备有强绑定关系时，可以不用调用此接口
    /// - Parameters:
    ///   - deviceIds: 设备id数组 0 < count <= 100
    ///   - TTL: 授权分钟数
    ///   - responseHandler: 回调
    func temporaryVisit(deviceIds: [String], TTL: Int, responseHandler: IVTencentNetworkResponseHandler) {
        let accessId = UserDefaults.standard.value(forKey: demo_accessId) ?? ""
        self.request(methodType: .POST,
                     action: "CreateDevToken",
                     params: ["AccessId": accessId,
                              "Tids.N": deviceIds,
                              "TtlMinutes": TTL],
                     response: responseHandler)
    }
    
    func queryBuyedCloudStoragePackage(serviceId: String, responseHandler: IVTencentNetworkResponseHandler) {
        self.request(methodType: .POST,
                     action: "DescribeStorageService",
                     params: ["ServiceId": serviceId,
                              "GetFinishedOrder": false],
                     response: responseHandler)
    }
    
    func buyCloudStoragePackage(packageID: String, deviceId: String, responseHandler: IVTencentNetworkResponseHandler) {
//        let accessId = UserDefaults.standard.string(forKey: demo_accessId) ?? ""
        self.request(methodType: .POST,
                     action: "CreateStorageService",
                     params: ["PkgId": packageID,
                              "Tid": deviceId,
                              "OrderCount": 1,
                              "StorageRegion": "ap-guangzhou"],
                     response: responseHandler)
    }
}


//正常登陆：腾讯控制台获取的 id,key和用户名
//临时授权登陆：腾讯控制台获取的 临时id,key,token和用户名
struct TXAccount {
    @Trimmed var userName: String
    @Trimmed var secretId: String
    @Trimmed var secretKey: String
    @Trimmed var tempToken: String
}
