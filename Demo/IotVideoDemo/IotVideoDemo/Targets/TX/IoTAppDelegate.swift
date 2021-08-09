//
//  YSAppDelegate.swift
//  IotVideoDemoYS
//
//  Created by zhaoyong on 2020/6/15.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import IoTVideo
import IVDevTools


extension AppDelegate {
    
    func setupIoTVideo(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)  {
        IoTVideo.sharedInstance.options = [
            .appVersion: Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String,
            .appPkgName : Bundle.main.bundleIdentifier!,
        ]
        if let hostWeb = IVConfigMgr.cfgValue(forKey: IVOptionKey.hostWeb.rawValue) {
            IoTVideo.sharedInstance.options[.hostWeb] = hostWeb
        }
        if let hostP2P = IVConfigMgr.cfgValue(forKey: IVOptionKey.hostP2P.rawValue) {
            IoTVideo.sharedInstance.options[.hostP2P] = hostP2P
        }
        if let devType = IVConfigMgr.cfgValue(forKey: IVOptionKey.appDevType.rawValue) {
            IoTVideo.sharedInstance.options[.appDevType] = devType
        }

        IoTVideo.sharedInstance.setup(launchOptions: launchOptions)
        IoTVideo.sharedInstance.delegate = self
        IoTVideo.sharedInstance.logLevel = IVLogLevel(rawValue: logLevel) ?? .DEBUG
        
        IVConfigMgr.addCfgObserverInvoke(forKey: "IOT_AV_DEBUG") { (cfg) in
            IVPlayer.debugMode = cfg.enable
        }
    }
}

extension AppDelegate: IoTVideoDelegate {
    func didUpdate(_ linkStatus: IVLinkStatus) {
//        logInfo("linkStatus: \(linkStatus.rawValue)")
        let linkDesc: [IVLinkStatus : String] = [.online : "在线",
                                                 .offline : "离线",
                                                 .tokenFailed : "Token校验失败",
                                                 .kickOff : "账号被踢飞"]
        let stStr = linkDesc[linkStatus] ?? ""
        window?.makeToast("SDK状态:"+stStr, duration: 2, position: .top)
        if linkStatus == .kickOff {
            IVNotiPost(.logout(by: .kickOff))
        }
    }
    
    func didOutputPrettyLogMessage(_ message: String) {
        IVLogger.logMessage(message)
    }    
}
