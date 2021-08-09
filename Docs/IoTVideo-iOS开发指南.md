# 快速开始

## 第一步：集成

**平台支持**：

| 平台 | SDK 及兼容性          | SDK 及 Demo                                                  |
| :--- | :-------------------- | :----------------------------------------------------------- |
| iOS  | Xcode 10.2+, iOS 9.0+ | 填写 [申请表](https://cloud.tencent.com/apply/p/ozpml9a5po) 进行申请，完成申请后，相关工作人员将联系您进行需求沟通，并提供对应 SDK 及 Demo |

将IoTVideoSDK集成到您的项目中并配置工程依赖，就可以完成SDK的集成工作。

> 详情请参见 [【集成指南】](#集成指南)

## 第二步：接入准备

开始使用 SDK 前，我们需要先获得终端用户访问IoTVideo云平台的两个关键参数：`accessId`(**唯一性身份标识**)和`accessToken`(**接入授权凭证**)，有如下2种获取方式：

- **方式1. 正常注册/登陆方式获取 **
  厂商云自建账号体系，通过云对接方式获取，详情参见 [终端用户注册](https://cloud.tencent.com/document/product/1131/42370) 和 [终端用户接入授权](https://cloud.tencent.com/document/product/1131/42365)。

- **方式2. 临时访问设备授权 **
  允许终端用户短时或一次性临时访问设备，详情参见 [终端用户临时访问设备授权](https://cloud.tencent.com/document/product/1131/42366)。

⚠️注意：使用SDK和操作设备都依赖于`accessId`和`accessToken`的加密校验，非法参数将产生异常。

## 第三步：SDK初始化

### 1、初始化

在 `AppDelegate` 中的`application:didFinishLaunchingWithOptions:`调用如下初始化方法：

```swift
import IoTVideo

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) {
      // 初始化
      IoTVideo.sharedInstance.setup(launchOptions: launchOptions)
      // 设置代理
      IoTVideo.sharedInstance.delegate = self
      // 设置日志等级
      IoTVideo.sharedInstance.logLevel = .DEBUG
      
    	...
  }
}

/// 实现IoTVideoDelegate协议
extension AppDelegate: IoTVideoDelegate {
    // SDK状态回调
  	func didUpdate(_ linkStatus: IVLinkStatus) {
       print("sdkLinkStatus: \(linkStatus.rawValue)")
    }
    
    // SDK日志输出
    func didOutputPrettyLogMessage(_ message: String) {
        print(message)
    }
}

```

### 2、注册

使用[接入准备](#第二步：接入准备)中获得的`accessId`和`accessToken`注册SDK:

```swift
import IoTVideo

IoTVideo.sharedInstance.register(withAccessId: "********", accessToken: "********")
```
注册后请监听SDK状态回调：`-[IoTVideoDelegate didUpdateLinkStatus:]`，也可通过`-[IoTVideo linkStatus]`主动查询SDK状态，仅当状态为`IVLinkStatusOnline`(**在线状态**)才可正常使用SDK。

## 第四步：配网

通过[SDK初始化](#第三步：SDK初始化) 我们已经可以正常使用SDK，现在我们为设备配置上网环境。   

### 1.设备联网

APP通过`IVNetConfig.getBindToken()`接口请求配网token，同时APP需设置配网结果监听`IVNetConfig.observeNetCfgResult()`。然后APP将包含token在内的配网信息发送给设备，设备连接网络后会上报IoTVideo云平台，之后APP会收到配网结果回调。

> 详见[【设备配网】](#设备配网) 

### 2.设备绑定

APP收到配网回调后通过厂商云账号体系间接调用IoTVideo云平台设备绑定接口，具体操作请参见 [终端用户绑定设备接口](https://cloud.tencent.com/document/product/1131/42367) 进行设备绑定。

### 3.设备订阅

绑定成功后，IoTVideo云平台会返回访问设备授权`AccessToken`,  然后APP调用如下接口使SDK订阅设备：

```swift
import IoTVideo.IVNetConfig

IVNetConfig.subscribeDevice(withAccessToken: "********", deviceId: deviceId)
```

## 第五步：监控

通过[配网](#第四步：配网)使终端用户与设备建立关系链，然后就可以在APP上访问设备了。这一步我们使用`IVMonitorPlayer`对设备进行监控。

```swift
import IoTVideo

// 1.创建监控播放器
let monitorPlayer = IVMonitorPlayer(deviceId: device.deviceID)
// 如果是多源设备(NVR)，创建播放器时可指定源ID，例如"2"
// let monitorPlayer = IVMonitorPlayer(deviceId: device.deviceID, sourceId: 2)
// 2.设置播放器代理（回调）
monitorPlayer.delegate = self
// 3.添加播放器渲染图层
videoView.insertSubview(monitorPlayer.videoView!, at: 0)
monitorPlayer.videoView?.frame = videoView.bounds
// 4.开始播放，启动推拉流、渲染模块
monitorPlayer.play()
// 5.开启/关闭语音对讲（只支持MonitorPlayer/LivePlayer）
monitorPlayer.startTalking()
monitorPlayer.stopTalking()
// 6.停止播放，断开连接
monitorPlayer.stop()
```

> 详见[【多媒体】](#多媒体)

## 第六步：消息管理

```swift
import IoTVideo.IVMessageMgr

// 设备ID的字符串
let deviceId = dev.deviceId
// 模型路径的字符串
let path = "ProWritable._logLevel"
// 模型参数的字符串
let json = "{\"setVal\":0}"

// 1.读取属性
IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceId, path: path) { (json, error) in
    // do something here    
}

// 2.设置属性
IVMessageMgr.sharedInstance.writeProperty(ofDevice:deviceId, path: path, json: json) { (json, error) in
    // do something here    
}

// 模型路径的字符串
let actionPath = "Action.cameraOn"
// 模型参数的字符串
let actionJson = "{\"ctlVal\":1}"

// 3.执行动作
IVMessageMgr.sharedInstance.takeAction(ofDevice: deviceId, path: actionPath, json: actionJson) { (json, error) in
    // do something here    
}
```

> 详见[【消息管理】](#消息管理)


# 集成指南

本节主要介绍如何快速地将IoTVideoSDK集成到您的项目中，按照如下步骤进行配置，就可以完成 SDK 的集成工 作。

## 开发环境要求

- Xcode 10.2+
- iOS 9.0+

## 集成 SDK

**1. 登录 [物联网智能视频服务控制台](https://console.cloud.tencent.com/iot-video) 进行申请，申请完成后，相关工作人员将联系您进行需求沟通，并提供对应 SDK 及 Demo**。



**2. 将下载并解压得到的IoTVideo相关Framework添加到工程中, 并添加相应依赖库**


> ⚠️重要说明：SDK中的IoTVideo.framework和Demo中的IJKMediaFramework.framework皆依赖于FFmpeg库，为方便开发者能自定义FFmpeg库同时避免多个FFmpeg库代码冲突，自`v1.1(ebb)`版本起IoTVideo.framework将FFmpeg库分离出来，由开发者在APP工程中导入。此外，我们提供了一份基于`ff3.4`的FFmpeg库(非GPL)，位于`Demo/IotVideoDemo/IotVideoDemo/Frameworks/ffmpeg/lib`，仅供开发者参考使用，也可另行编译（注：自行编译的FFmpeg版本应考虑接口兼容问题）。

**必选库**：

- IoTVideo.framework (静态库)   // 核心库     
  - 依赖FFmpeg库 (必须)
- IVVAS.framework (静态库)      // 增值服务库

**可选库(选一个或不选)**：

- IJKMediaFramework.framework（静态库）// 用于播放云回放的http://xxxx.m3u8文件
  - 依赖FFmpeg库 (必须)
  - 依赖SSL库（可选）
- IJKMediaFrameworkWithSSL.framework（静态库）// 用于播放云回放的https://xxxx.m3u8文件
  - 依赖FFmpeg库 (必须)
  - 依赖SSL库（必选）

**依赖库**：

  - AudioToolbox.framework   
  - VideoToolbox.framework   
  - CoreMedia.framework 
  - FFmpeg库 (必须)
    - libavutil.a     
    - libavfilter.a     
    - libavcodec.a     
    - libavformat.a     
    - libswresample.a     
    - libswscale.a
  - SSL库（可选）
    - libcrypto.a
    - libssl.a
  - libc++.tbd
  - libz.tbd
  - libbz2.tbd
  - libiconv.tbd

![](https://note.youdao.com/yws/api/group/108650997/file/905721786?method=download&inline=true&version=1&shareToken=40D9119DB53148FFAB19556DACCC79EE)



**3. ⚠️注意： v1.0(da7)及之前版本需要设置TATGETS -> Build Phases -> Embed Frameworks为 Embed & sign，或者Xcode11后可在General -> Frameworks,Libraries,and Embedded Content 设置 Embed&Sign**

 ![image](https://note.youdao.com/yws/api/group/108650997/file/898850154?method=download&inline=true&version=2&shareToken=13D2636806184BB1931F4809D2A4C8F0)



**4. 其他设置**

  - v1.3(1f7d) 及之前版本需关闭Bitcode： TARGETS -> Build Settings -> Build Options -> Enable Bitcode -> NO
    ![image](https://note.youdao.com/yws/api/group/108650997/file/891138351?method=download&inline=true&version=3&shareToken=0C0D6A6794DE4F8BBEC81BD8497CDC41)
  - 设置APP权限，在info.plist中加入下方代码

  ```xml
  <key>NSCameraUsageDescription</key>
  <string>访问相机</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>访问麦克风</string>
  <key>NSPhotoLibraryAddUsageDescription</key>
  <string>访问相册</string>
  <key>NSPhotoLibraryUsageDescription</key>
  <string>访问相册</string>
  ```


# 设备配网

广义的设备配网包括**为设备配置上网环境**和**绑定设备**两个操作。

此SDK的配网模块用来为设备配置上网环境，IVNetConfig封装了局域网配网、二维码配网常用的一些方法，但SDK不局限于具体配网方式（即以下配网流程图中蓝色框部分），开发者可自行选择。常见配网方式有**有线配网、AP配网、二维码配网**等，配网流程如下所示。

设备绑定具体操作请参见 [终端用户绑定设备接口](https://cloud.tencent.com/document/product/1131/42367) 进行设备绑定。

## 配网流程

![](https://tva1.sinaimg.cn/large/008i3skNgy1gse8ekd9z1j310o0owaav.jpg)

## 配网示例

### 1. 有线配网

适用于自带网口的设备，省去了配网环节，APP可通过局域网搜索到目标设备，使用设备ID向服务器发起绑定请求。  
流程大致如下：

> 1. APP连接到与设备同一网络下的Wi-Fi
> 2. APP搜索到目标设备，取得目标设备ID
> 3. APP向服务器发起绑定目标设备的请求
> 4. 绑定设备成功
> 5. 订阅该设备
> 6. 配网结束

- 代码示例

```swift
import IoTVideo.IVNetConfig

// 1. 获取局域网设备列表
let deviceList: [IVLANDevice] = IVNetConfig.lan.getDeviceList()

// 2. 取得目标设备ID
let deviceId = deviceList[i].deviceId

// 3. [可选]向服务器请求配网BindToken
IVNetConfig.getBindToken { (token, error) in
    // 取得配网token
}

// 4. [可选]设置监听配网结果回调/设备可绑定状态
IVNetConfig.observeNetCfgResult { (deviceId, error) in
    // 取得设备可绑定状态
}

// 5. 绑定设备
APP调用厂商云封装的绑定接口，参考[终端用户绑定设备](https://cloud.tencent.com/document/product/1131/42367)
                                                              
// 6. [可选]移除配网结果监听
IVNetConfig.removeObserver()

// 7. 订阅设备
// ⚠️这里的token参数不是`BindToken`，而是步骤[4.绑定设备]返回的`AccessToken`。
IVNetConfig.subscribeDevice(withAccessToken: "********", deviceId: deviceId)
```

### 2. AP配网

AP配网模式下设备会发出Wi-Fi热点，APP连接该设备热点，使APP与设备建立局域网连接，当然这个Wi-Fi热点并不能上网，只能用于局域网信息传递。  
流程大致如下：

> 1. 设备复位进入配网模式并发射Wi-Fi热点
> 2. APP连接设备的热点（形成局域网）
> 3. APP向服务器请求配网授权BindToken
> 4. APP向设备发送BindToken和目标路由器Wi-Fi信息
> 5. 设备收到Wi-Fi信息后去连接指定网络
> 6. 设备连接网络并上报服务器
> 7. APP收到设备配网结果消息
> 8. APP向服务器发起绑定目标设备的请求
> 9. 绑定设备成功
> 10. 订阅该设备
> 11. 配网结束

- 代码示例

```swift
import IoTVideo.IVNetConfig

// 1. 连接设备热点,获取设备信息
let dev = IVNetConfig.lan.getDeviceList().first()

// 2. [可选]向服务器请求配网BindToken
IVNetConfig.getBindToken { (token, error) in
    // 取得配网token
}

// 3. [可选]设置监听配网结果回调/设备可绑定状态
IVNetConfig.observeNetCfgResult { (deviceId, error) in
    // 取得设备可绑定状态，转到[5. 绑定设备]
}

// 4. 通过局域网发送配网信息
IVNetConfig.lan.sendWifiName("***", wifiPassword: "***", token: token, toDevice: dev.deviceID) { (success, error) in
    if success {
       //发送成功，开始监听事件通知
    } else {
       //发送失败
    }
}
    
// 5. 绑定设备
APP调用厂商云封装的绑定接口，参考[终端用户绑定设备](https://cloud.tencent.com/document/product/1131/42367)
                                                              
// 6. [可选]移除配网结果监听
IVNetConfig.removeObserver()

// 7. 订阅设备
// ⚠️这里的token参数不是`BindToken`，而是步骤[4.绑定设备]返回的`AccessToken`。
IVNetConfig.subscribeDevice(withAccessToken: "********", deviceId: deviceId)
```

设备绑定具体操作请参见 [终端用户绑定设备接口](https://cloud.tencent.com/document/product/1131/42367) 进行设备绑定。

### 3. 二维码配网

二维码配网原理是APP使用配网信息生成二维码，设备通过摄像头扫描二维码获取配网信息。 
流程大致如下：

> 1. 设备复位进入配网模式，摄像头开始扫描二维码
> 2. APP向服务器请求配网，得到BindToken
> 3. APP使用BindToken和Wi-Fi信息生成二维码
> 4. 用户将二维码出示给设备扫描
> 5. 设备解析出Wi-Fi信息后去连接指定网络
> 6. 设备连接网络并上报服务器
> 7. APP收到设备配网结果消息
> 8. APP向服务器发起绑定目标设备的请求
> 9. 绑定设备成功
> 10. 订阅该设备
> 11. 配网结束

步骤3中开发者需自定义传递给设备的数据结构（建议数据不要太长，否则二维码太复杂设备难以识别），然后使用SDK内置工具类`IVNetConfig.qrCode.createQRCode`生成二维码（也可自行生成二维码）。

- 代码示例

```swift
import IoTVideo.IVNetConfig

// 1. 获取配网token
IVNetConfig.getBindToken { (token, error) in
    // 取得配网token
}

// 2. [可选]设置监听配网结果回调/设备可绑定状态
IVNetConfig.observeNetCfgResult { (deviceId, error) in
    // 取得设备可绑定状态，转到[5. 绑定设备]
}

// 3. 生成二维码 使用得到的配网token加上wifi信息
let image = IVNetConfig.qrCode.createQRCode(withWifiName: ssid,
                                            wifiPassword: password,
                                                   token: token)

// 4.用户将二维码出示给设备扫描....

// 5. 绑定设备
APP调用厂商云封装的绑定接口，参考[终端用户绑定设备](https://cloud.tencent.com/document/product/1131/42367)
                                                              
// 6. [可选]移除配网结果监听
IVNetConfig.removeObserver()

// 7. 订阅设备
// ⚠️这里的token参数不是`BindToken`，而是步骤[4.绑定设备]返回的`AccessToken`。
IVNetConfig.subscribeDevice(withAccessToken: "********", deviceId: deviceId)
```


# 多媒体

多媒体模块为SDK提供音视频能力，包含实时监控、实时音视频通话、远程回放、录像、截图、下载、透传等功能。
## 播放器

### 功能概览

![播放器集合图](https://tva1.sinaimg.cn/large/008i3skNgy1gs8i7grxj6j30im0ga3yn.jpg)

#### 基础播放器(IVPlayer)

IVPlayer是整个多媒体模块的核心，主要负责以下流程控制：

- 音视频通道维护
- 音视频流推拉
- 协议解析
- 封装和解封装
- 音视频编/解码
- 音视频同步
- 音视频渲染
- 音视频录制
- 播放状态控制

其中，*音视频编/解码* 和 *音视频渲染* 流程允许开发者自定义实现（*⚠️播放器已内置实现，不推荐自定义实现*）  

#### 监控播放器(MonitorPlayer)

MonitorPlayer是基于IVPlayer派生的监控播放器，主要增加以下功能：

- 语音对讲

#### 音视频通话播放器(LivePlayer)

LivePlayer是基于IVPlayer派生的音视频通话播放器，主要增加以下功能：

- 语音对讲
- 双向视频

#### 回放播放器(PlaybackPlayer)

PlaybackPlayer是基于IVPlayer派生的回放播放器，主要增加以下功能：

- 暂停/恢复
- 跳至指定位置播放
- 倍速播放

### 播放器功能特性

| 功能              |  监控播放器  |  回放播放器  |  音视频通话 |
| ----------------- | ---------- | ---------- | ---------- |
| 视频播放           | ✓          | ✓          | ✓          |
| 音频播放           | ✓          | ✓          | ✓          |
| 状态变更通知        | ✓          | ✓          | ✓          |
| 静音播放           | ✓          | ✓          | ✓          |
| 画面缩放           | ✓          | ✓          | ✓          |
| 播放器截图         | ✓          | ✓          | ✓          |
| 画面录制           | ✓          | ✓          | ✓          |
| 用户数据传输        | ✓          | ✓          | ✓          |
| 暂停/恢复          | x          | ✓          | x          |
| 跳至指定位置播放    | x          | ✓          | x          |
| 倍速播放           | x          | ✓          | x          |
| 总时长             | x          | ✓          | x          |
| 当前播放进度        | x          | ✓          | x          |
| 分辨率切换         | ✓          | x          | x          |
| 双向语音           | ✓          | x          | ✓          |
| 双向视频           | x          | x          | ✓          |


### 播放器使用示例

1.创建播放器

*⚠️ 注意：如果是多源设备(NVR)，创建播放器时可指定源ID，例如"2"*

```swift
import IoTVideo

// 监控播放器
let monitorPlayer = IVMonitorPlayer(deviceId: device.deviceID)
// let monitorPlayer = IVMonitorPlayer(deviceId: device.deviceID, sourceId: 2) //For NVR

// 音视频通话播放器
let livePlayer = IVLivePlayer(deviceId: device.deviceID)
//let livePlayer = IVLivePlayer(deviceId: device.deviceID, sourceId: 2) //For NVR

// 回放播放器
let playbackPlayer = IVPlaybackPlayer(deviceId: device.deviceID, playbackItem: item, seekToTime: time)
//let playbackPlayer = IVPlaybackPlayer(deviceId: device.deviceID, playbackItem: item, seekToTime: time, sourceId: 2) //For NVR

```

*⚠注意：以下使用`xxxxPlayer`泛指支持该功能的播放器*

2.设置播放器代理

```swift
xxxxPlayer.delegate = self
```

3.添加摄像头预览图层

*⚠只支持IVLivePlayer*

```swift
previewView.layer.addSublayer(livePlayer.previewLayer)
livePlayer.previewLayer.frame = previewView.bounds
```

4.添加播放器视图

```swift
videoView.insertSubview(xxxxPlayer.videoView!, at: 0)
xxxxPlayer.videoView?.frame = videoView.bounds
```

5.开始播放

```swift
xxxxPlayer.play() //播放，开始推拉流、渲染模块等
```

6.语音对讲

*⚠只支持MonitorPlayer/LivePlayer*

```swift
xxxxPlayer.startTalking() //开启
xxxxPlayer.stopTalking()  //关闭
```

7.操作摄像头

*⚠只支持IVLivePlayer*

```swift
livePlayer.openCamera() 	//打开摄像头
livePlayer.switchCamera() //切换摄像头
livePlayer.closeCamera() 	//关闭摄像头
```

8.跳转到指定时间

*⚠只支持IVPlaybackPlayer*

```swift
playbackPlayer.seek(toTime: time, playbackItem: item) //跳转到指定文件的指定时间
```

9.暂停恢复

*⚠只支持IVPlaybackPlayer*

```swift
playbackPlayer.pause()  //暂停
playbackPlayer.resume() //恢复
```

10.倍速播放

*⚠只支持IVPlaybackPlayer*

```swift
playbackPlayer.speed = 8.0 //倍速，取值范围0.5～32.0，默认1.0
```

11.停止播放

```swift
xxxxPlayer.stop() //停止，断开连接，结束推拉流、渲染模块等
```

### 高级功能

播放器默认使用内置采集器、编解码器、渲染器等功能模块，但允许开发者在调用`player.play()`前对内置功能模块进行某些参数修改，甚至可以根据协议自定义实现功能模块。

>  ⚠️注意：音视频编解码及渲染等已默认由基础播放器实现。如无必要，无需另行实现。

- #### 基础播放器可自定义模块

| 可自定义模块 |         协议名     |     内置实现类    |   播放器属性名  |
| ---------- | ----------------- | --------------- | -------------- |
| 音频解码器   | IVAudioDecodable  | IVAudioDecoder  | audioDecoder   |
| 视频解码器   | IVVideoDecodable  | IVVideoDecoder  | videoDecoder   |
| 音频渲染器   | IVAudioRenderable | IVAudioRender   | audioRender    |
| 视频渲染器   | IVVideoRenderable | IVVideoRender   | videoRender    |
| 音视频录制器 | IVAVRecordable    | IVAVRecorder    | avRecorder     |

接口如下：
```swift
class IVPlayer {
  	/// 音频解码器, 默认内置实现为`IVAudioDecoder`类
    open var audioDecoder: (Any & IVAudioDecodable)?
    
  	/// 视频解码器, 默认内置实现为`IVVideoDecoder`类
    open var videoDecoder: (Any & IVVideoDecodable)?
    
  	/// 音频渲染器, 默认内置实现为`IVAudioRender`类
    open var audioRender: (Any & IVAudioRenderable)?
    
    /// 视频渲染器, 默认内置实现为`IVVideoRender`类
    open var videoRender: (Any & IVVideoRenderable)?
    
  	/// 音视频录制器, 默认内置实现为`IVAVRecorder`类
    open var avRecorder: (Any & IVAVRecordable)?
}
```

- #### 可对讲播放器可自定义模块

| 可自定义模块 |         协议名     |     内置实现类    |   播放器属性名  |
| ---------- | ----------------- | --------------- | -------------- |
| 音频采集器   | IVAudioCapturable  | IVAudioCapture  | audioCapture   |
| 音频编码器   | IVAudioEncodable  | IVAudioEncoder  | audioEncoder   |

接口如下：

```swift
public protocol IVPlayerTalkable {    
    /// 音频采集器, 默认内置实现为`IVAudioCapture`类
    open var audioCapture: (Any & IVAudioCapturable)
  
    /// 音频编码器, 默认内置实现为`IVAudioEncoder`类
    open var audioEncoder: (Any & IVAudioEncodable)
}
```

- #### 可视频播放器可自定义模块

| 可自定义模块 | 协议名            | 内置实现类     | 播放器属性名 |
| ------------ | ----------------- | -------------- | ------------ |
| 视频采集器   | IVVideoCapturable | IVVideoCapture | videoCapture |
| 视频编码器   | IVVideoEncodable  | IVVideoEncoder | videoEncoder |

接口如下：

```swift
// 可视频播放器可自定义模块
protocol IVPlayerVideoable {
    /// 视频采集器, 默认内置实现为`IVVideoCapture`类
    open var videoCapture: (Any & IVVideoCapturable)?
    
  	/// 视频编码器, 默认内置实现为`IVVideoEncoder`类
    open var videoEncoder: (Any & IVVideoEncodable)?
}
```

- #### **使用示例**

  内置实现，但修改某些参数

```swift
// 1. 播放前修改参数
if let player = xxxxPlayer as? IVPlayerTalkable {
    // player.audioEncoder.audioType = .AMR // 默认AAC
    // player.audioEncoder = MyAudioEncoder() // 自定义audioEncoder
    player.audioCapture.sampleRate = 16000 // 默认8000
}
if let player = xxxxPlayer as? IVPlayerVideoable {
    // player.videoEncoder.videoType = .H264 // 默认H264
    player.videoCapture.definition = .mid // 默认low
}
// 2. 开始播放
xxxxPlayer.play()
```

- **使用自定义实现替换内置实现**

```swift
// 1. 根据协议自定义实现
class MyAudioDecoder: IVAudioDecodable {
  ...
}
class MyVideoRender: IVVideoRenderable {
  ... 
}

// 2. 播放前替换成自定义实现
player.videoRender = MyVideoRender() // 自定义videoRender
player.audioDecoder = MyAudioDecoder() // 自定义audioDecoder

// 3. 开始播放
xxxxPlayer.play()
```

## 文件下载
此功能用于下载卡回放文件，由`IVFileDownloader`类实现。

- 开始下载
```swift
/// 开始下载（恢复下载）
/// 此方法内部会自动建立连接，支持断点续传
/// 设备在发送文件完毕后会等待新的下载动作，超过10秒还没有收到任何动作，设备会主动断开连接(20136）。
/// @note 一台设备同一时间内只能下载一个文件，若要切换下载的文件请先暂停当前下载的文件。
/// @param fileTime 要下载的文件的开始时间(ms), 用于识别是哪个文件 @c `IVPlaybackItem.startTime`
/// @param offset 断点续传时填字节偏移量（即当前已下载字节数），重新下载填0
/// @param ready 文件已就绪回调，即将接收数据，`fileSize`:文件总大小
/// @param progress 下载过程回调，可能回调多次，`data`:文件内容
/// @param paused 下载暂停回调
/// @param success 下载完成回调
/// @param failure 下载失败回调,  @c `IVConnError`和`IVDownloadError`
open func downloadPlaybackFile(_ fileTime: UInt64, offset: UInt32, ready: @escaping (UInt32) -> Void, progress: @escaping (Data) -> Void, paused: @escaping () -> Void, success: @escaping () -> Void, failure: @escaping (Error) -> Void)
```

- 暂停下载
```swift
/// 暂停下载
/// 设备将暂停传输，关闭该文件句柄，然后进入10秒倒计时，若期间没有收到任何动作，设备会主动断开连接(20136）
open func pause()
```
- 停止下载
```swift
/// 停止下载，并断开与设备的连接
open func stop()
```

## 自定义数据传输

此功能允许用户在建立通道连接之后传输自定义数据，例如硬件模块开关、交互指令、额外的多媒体信息等，由`IVTransmission`类实现。

- 连接与断开连接
```swift
/// 通道连接（抽象类，不要直接实例化，请使用其派生类: IVLivePlayer / IVPlaybackPlayer / IVMonitorPlayer / IVTransmission）
open class IVConnection : NSObject {
    
    /// 开始连接
    open func connect() -> Bool

    /// 断开连接
    open func disconnect() -> Bool
```

- 发送自定义数据

说明：`#define MAX_DATA_SIZE 64000`

```swift
    /// 发送自定义数据
    ///
    /// 需要与设备建立专门的连接通道，适用于较大数据传输、实时性要求较高的场景，如多媒体数据传输。
    /// @param data 要发送的数据，data.length不能超过`MAX_PKG_BYTES`
    /// @return 发送是否成功
    open func send(_ data: Data) -> Bool
}
```

- 接收数据

```swift
/// 连接代理
public protocol IVConnectionDelegate : NSObjectProtocol {
    /// 收到数据
    /// @param connection 连接实例
    /// @param data 数据
    func connection(_ connection: IVConnection, didReceive data: Data)
}
```


# 消息管理

消息管理模块负责APP与设备、服务器之间的消息传递，主要包含以下功能：

- 在线消息回调
  - 接收到事件消息（Event）:  告警、分享、系统通知
  - 接收到状态消息（ProReadonly）
- 控制/操作设备（Action）
- 设置设备参数（ProWritable）
- 获取设备状态（ProReadonly）
- 获取设备参数（ProWritable）
- 信令数据透传  (Data)

## 物模型

### 1.状态和事件消息通知

```swift
import IoTVideo.IVMessageMgr

class MyViewController: UIViewController, IVMessageDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 设置消息代理
        IVMessageMgr.sharedInstance.delegate = self
    }
    
    // MARK: - IVMessageDelegate
    
    // 接收到事件消息（Event）:  告警、分享、系统通知
    func didReceiveEvent(_ event: String, topic: String) {
        // do something here
    }
    
    // 接收到状态消息（ProReadonly）
    func didUpdateProperty(_ json: String, path: String, deviceId: String) {
        // do something here
    }
}
```

### 2.读取属性

`path`为空字符串`""`则表示获取完整物模型

```swift
import IoTVideo.IVMessageMgr

// 设备ID的字符串
let deviceId = dev.deviceId
// 模型路径的字符串
let path = "ProWritable._logLevel"

IVMessageMgr.sharedInstance.readProperty(ofDevice: deviceId, path: path) { (json, error) in
    // do something here    
}
```

### 3.设置属性

```swift
import IoTVideo.IVMessageMgr

// 设备ID的字符串
let deviceId = dev.deviceId
// 模型路径的字符串
let path = "ProWritable._logLevel"
// 模型参数的字符串
let json = "{\"setVal\":0}"

// 或
let path = "ProWritable._logLevel.setVal"
let json = "0" //代表整型
let json = "\"value\"" // 代表字符串

IVMessageMgr.sharedInstance.writeProperty(ofDevice: deviceId, path: path, json: json) { (json, error) in
    // do something here    
}
```

### 4.执行动作

```swift
import IoTVideo.IVMessageMgr

let deviceId = dev.deviceId
let path = "Action.cameraOn"
let json = "{\"ctlVal\":1}"

IVMessageMgr.sharedInstance.takeAction(ofDevice: deviceId, path: path, json: json) { (json, error) in
    // do something here    
}
```

### 5. 用户自定义属性

#### 5.1 新增用户自定义属性

 - 禁止使用"\_"开头，"_"为内置物模型使用（使用了会报错：8605）
 - 重复新增会直接覆盖已经存在的自定义用户物模型

```swift
import IoTVideo.IVMessageMgr

let deviceId = dev.deviceId
// 新增的用户属性
let subPath = "userPro1" 
let path = "ProUser." + subPath
let json = "{\"key\":\"value\"}"

IVMessageMgr.sharedInstance.addProperty(ofDevice: deviceId, path: path, json: json) { (json, error) in
    // do something here
}
```

#### 5.2 删除用户自定义属性

```swift
import IoTVideo.IVMessageMgr

let deviceId = dev.deviceId
let path = "ProUser.userPro1"

IVMessageMgr.sharedInstance.deleteProperty(ofDevice: deviceId, path: path) { (json, error) in
    // do something here
}
```

#### 5.3 修改用户物模型

与 3.设置属性 同一个API，注意 `path` 和 `json` 的细微差别
|        修改值        | 内容 | 可用示例 |
| :----------------: | :--------: | :--------: |
| ProWritable  | 读写属性 | `path = ProWritable.xxx json = "{\"setVal\":\"value\"}"` <br> 或字符串：`path = Prowritable.xxx.setVal json = "\"value\""` <br> |
| ProUser | 自定义用户属性| `path = ProWritable.xxx.val json = "{\"key\":\"value\"}"` |
| ProUser | 内 置 用 户 属性| `path = "ProUser._buildIn.val.xxx" json = "value" ` |

```swift
import IoTVideo.IVMessageMgr

let deviceId = dev.deviceId

// 1、用户自定义的ProUser属性 实例: 
// "testProUser":{"t":1600048390,"val":{"testKey":"testValue"}}

// path 必须拼接为 ProUser.xxx.val 
let path = "ProUser.testProUser.val" 
let json = "{\"testKey\":\"newTestValue\"}"

IVMessageMgr.sharedInstance.writeProperty(ofDevice: deviceId, path: path, json: json) { (json, error) in
    // do something here    
}

// 2、系统内置的ProUser属性 实例：
// "_buildIn":{"t":1599731880,"val":{"almEvtPushEna":0,"nickName":"testName"}

// path必须拼接为 ProUser._buildIn.val._xxx 
let path = "ProUser._buildIn.val.nickName"
let json = "\"newNickName\""

IVMessageMgr.sharedInstance.writeProperty(ofDevice: deviceId, path: path, json: json) { (json, error) in
    // do something here    
}
```

## 信令数据透传

### 1. 透传数据给设备

- 说明：`#define MAX_DATA_SIZE 30000`

```swift
/// 透传数据给设备（无数据回传）
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性不高、数据小于`MAX_DATA_SIZE`、不需要回传的场景，如控制指令。
/// @note 完成回调条件：收到ACK 或 消息超时
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
open func sendData(toDevice deviceId: String, data: Data, withoutResponse completionHandler: IVMsgDataCallback? = nil)

/// 透传数据给设备（有数据回传）
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性不高、数据小于`MAX_DATA_SIZE`、需要回传的场景，如获取信息。
/// @note 完成回调条件：收到ACK错误、消息超时 或 有数据回传
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
open func sendData(toDevice deviceId: String, data: Data, withResponse completionHandler: IVMsgDataCallback? = nil)

/// 透传数据给设备
///
/// 不需要建立通道连接，数据经由服务器转发，适用于实时性要求不高，数据小于`MAX_DATA_SIZE`的场景，如控制指令、获取信息。
/// @note 相关接口 @c `sendDataToDevice:data:withoutResponse:`、`sendDataToDevice:data:withResponse:`。
/// @param deviceId 设备ID
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param timeout 自定义超时时间，默认超时时间可使用@c `IVMsgTimeoutAuto`
/// @param expectResponse 【YES】预期有数据回传 ；【NO】忽略数据回传
/// @param completionHandler 完成回调
open func sendData(toDevice deviceId: String, data: Data, timeout: TimeInterval, expectResponse: Bool, completionHandler: IVMsgDataCallback? = nil)

```

### 2. 透传数据给服务器

```swift
/// 透传数据给服务器
/// @param url 服务器路径
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param completionHandler 完成回调
open func sendData(toServer url: String, data: Data?, completionHandler: IVMsgDataCallback? = nil)

/// 透传数据给服务器
/// @param url 服务器路径
/// @param data 数据内容，data.length不能超过`MAX_DATA_SIZE`
/// @param timeout 超时时间
/// @param completionHandler 完成回调
open func sendData(toServer url: String, data: Data?, timeout: TimeInterval, completionHandler: IVMsgDataCallback? = nil)
```

## 设备管理
### 1、查询设备固件版本号
不通过物模型查询最新版本号，当设备离线时也可用
```swift
/// 查询设备新固件版本信息
/// @param deviceId 设备id
/// @param responseHandler 回调
open class func queryDeviceNewVersionWidthDevieId(_ deviceId: String, responseHandler: @escaping IVNetworkResponseHandler)

/// 查询设备新固件版本信息
/// @param deviceId 设备id
/// @param currentVersion 当前设备版本号。nil:默认为当前设备版本号；新版本固件可以指定哪些设备版本可以查询到有固件更新，这种场景下[不传版本] 和 [不在指定版本列表里面]就查询不到更新
/// @param language 语言 nil：默认系统语言
/// @param responseHandler 回调
open class func queryDeviceNewVersionWidthDevieId(_ deviceId: String, currentVersion: String?, language: String?, responseHandler: @escaping IVNetworkResponseHandler)

```

- 应用示例
```swift
import IoTVideo.IVDeviceMgr

IVDeviceMgr.queryDeviceNewVersionWidthDevieId("xxxx") { (json, error) in
    // do something here    
}

IVDeviceMgr.queryDeviceNewVersionWidthDevieId("xxxx", currentVersion:"1.0.0", language:"en") { (json, error) in
    // do something here    
}
```

其中，json结构如下
```json
{
    "code": 0,
    "msg": "Success",
    "data": {
        "downUrl": "xxxxxxxxx", 
        "version": "xxxxxxxxx", //版本号
        "upgDescs": "xxxxxxxxx" //升级描述
    }
}
```

# 增值服务
## 功能概述

主要包含以下功能：

### 1. 基本信息

- 查询云存相关信息

### 2. 视频相关
- 查询存在云存的日期信息
- 获取回放文件列表
- 获取回放 m3u8 播放地址
###  3. 事件相关
- 获取事件列表
- 删除事件（可批量）

## 接口详情
### 1. 查询设备的云存详细信息

```swift
/// 查询设备的云存详细信息
/// @param deviceId 设备id
/// @param responseHandler 回调
open func getServiceDetailInfo(withDeviceId deviceId: String, responseHandler: IVNetworkResponseHandler? = nil)

/// 查询多通道设备的云存详细信息
/// @param deviceId 设备id
/// @param sourceId 源ID
/// @param responseHandler 回调
open func getServiceDetailInfo(withDeviceId deviceId: String, sourceId: Int, responseHandler: IVNetworkResponseHandler? = nil)
```

- 返回结果：json 示例
```json
{  
    "code":0,  
    "msg":"Success",  
    "data":{  
        "status":1,  
        "startTime":1606709335,  
        "endTime":1611979735,  
        "curOrderPkgType":1,  
        "curOrderStorageDays":3,  
        "curOrderStartTime":1606709335,  
        "curOrderEndTime":1606709335,  
        "playbackDays":3
    }  
}  
```
- 对应 data 结构

参数名称             |类型           |描述
---------------------|---------------|-----
status               |Integer        |云存服务状态。
startTime            |Integer        |云存服务开始时间。
endTime              |Integer        |云存服务失效时间。
curOrderPkgType      |Integer        |当前订单类型。
curOrderStorageDays  |Integer        |当前订单存储时长，单位天。
curOrderStartTime    |Integer        |当前订单开始时间。
curOrderEndTime      |Integer        |当前订单结束事件。
playbackStartTime    |Integer        |当前云存服务，支持检索回放文件的最早时间。<br> 这个时间点之前的云存文件不支持检索。

- 云存服务状态

值   | 描述                      
---  | -------------------       
 1   | 正常使用中。             
 2   | 待续费。设备云存服务已到期，但是历史云存数据未过期。续费后仍可查看这些历史数据。
 3   | 已过期。查询不到设备保存在云端的数据。

- 订单类型

值   | 描述                      
---  | -------------------       
 1   | 全时云存             
 2   | 事件云存
### 2.查询存在云存的日期信息

```swift
/// 获取云存视频可播放日期信息（可匿名访问）
/// - 用于终端用户在云存页面中对云存服务时间内的日期进行标注，区分出是否有云存视频文件。
/// @param deviceId 设备id
/// @param timezone 相对于0时区的秒数，例如东八区28800
/// @param responseHandler 回调
open func getVideoDateList(withDeviceId deviceId: String, timezone: Int, responseHandler: IVNetworkResponseHandler? = nil)
```

返回结果：json 示例
```json
{
    "code":0,
    "msg":"Success",
    "data":{
        "list":[
            1600653494
        ]
    }
}
```

### 3. 获取回放文件列表
```swift
/// 获取回放文件列表（可匿名访问）
/// - 获取云存列表，用户对时间轴渲染
/// @param deviceId 设备id
/// @param startTime 开始UTC时间,单位秒
/// @param endTime 结束UTC时间,单位秒 超过一天只返回一天
/// @param responseHandler 回调
open func getVideoPlayList(withDeviceId deviceId: String, startTime: TimeInterval, endTime: TimeInterval, responseHandler: IVNetworkResponseHandler? = nil)
```

返回结果：json 示例
```json
{
    "msg":"Success",
    "code":0,
    "data":{
        "list":[
            {
                "start":1601285768,
                "end":1601285776
            },
            {
                "start":1601285780,
                "end":1601285800
            }
        ]
    },
}
```
### 4.获取回放 m3u8 播放地址

```objc
/// 获取回放 m3u8 播放地址（可匿名访问）
/// @param deviceId 设备id
/// @param startTime 开始UTC时间,单位秒
/// @param endTime 结束UTC时间,单位秒 填 0 则默认播放到最新为止
/// @param responseHandler 回调
/// json:
/// endflag boolean 播放结束标记， 表示此次播放是否把需要播放的文件播完，没有则需以返回的 endtime 为基准再次请求。false 表示未播放完，true 表示播放完成
open func getVideoPlayAddress(withDeviceId deviceId: String, startTime: TimeInterval, endTiem endTime: TimeInterval, responseHandler: IVNetworkResponseHandler? = nil)
```

返回结果：json 示例
```json
{
    "code":0,
    "msg":"Success",
    "data":{
        "endTime":1601289368,
        "endflag":true,
        "startTime":1601285768,
        "url":"http://lcb.iotvideo.tencentcs.com/timeshift/live/00000101000e00fc000000000000000007000000b2860100/timeshift.m3u8?starttime=20200928173608&endtime=20200928183608"
    }
}
```

对应data 结构：
参数名称|类型   |描述
--------|-------|-----
url     |string |m3u8文件地址
startTime|int64 |此处播放m3u8文件播放开始时间
endTime |int64  |此次m3u8文件播放结束时间
endflag |boolean|播放结束标记， 表示此次请求结果的m3u8能否把需要播放的时间内的文件播完，<br> 不能则需以返回的 `endtime` 为基准再次请求。<br>`false` 表示未播放完，`true` 表示播放完成


### 5.获取事件列表
```swift
/// 获取事件列表（可匿名访问）
///
/// @param deviceId 设备id
/// @param startTime 事件告警开始UTC时间, 一般为当天开始时间， 单位秒
/// @param endTime 事件告警结束UTC时间，获取更多应传入当前列表的最后一个事件的开始时间(事件列表按时间逆序排列)；
/// @param pageSize 本次最多查询多少条记录，取值范围 [1 - 50]
/// @param typeMasks 筛选指定类型的事件掩码数组：Array<UInt32>，
/// @param validCloudStorage 是否只返回有效云存期内的事件
/// @param responseHandler 回调 json, 其中pageEnd为分页结束标志
open func getEventList(withDeviceId deviceId: String, startTime: TimeInterval, endTime: TimeInterval, pageSize: Int, filterTypeMask typeMasks: [NSNumber]?, validCloudStorage: Bool, responseHandler: IVNetworkResponseHandler? = nil)
```
-  typeMask 过滤规则
  - bit[0-15]为SDK内置; bit[16 - 32]为调用者可自定义类型；bit15(即 0x8000)为标志有视频的事件；
  - 对于列表中**单个掩码**，每个bit按 **按位或** 规则来过滤，例如 almTypeMasks = [3], 其中`3`等于`bit0 | bit1`， 此时获取到的事件为 **包含bit0 或 bit1类型的事件**；
  - 对于列表中**掩码之间**，按 **按位与** 的规则来过滤， 例如 almTypeMasks = [1, 2], 其中`1` 等于 `bit0` ，`2` 等于 `bit1`， 此时获取到的事件为 **同时包含bit0 和 bit1类型的事件；**

- 应用示例

```swift
/// 加载更多
func getMoreEvents() {
    let endTime = eventList.last?.startTime ?? currDate + 86400
    IVVAS.shared.getEventList(withDeviceId: deviceID, startTime: currDate, endTime: endTime, pageSize: 50, filterTypeMask: 0) { [weak self](json, error) in
        /* get more data here */
    }
}

/// 下拉刷新
func refreshEvents() {
    let endTime = currDate + 86400
    IVVAS.shared.getEventList(withDeviceId: deviceID, startTime: currDate, endTime: endTime, pageSize: 50, filterTypeMask: 0) { [weak self](json, error) in
        /* new data here */
    }
}
```

返回结果：json 示例
```json
{
    "requestId":"xxxxxx",
    "code":0,
    "msg":"Success",
    "data":{
        "imgUrlPrefix":"xxxxx",
        "thumbUrlSuffix":"&xxxx",
        "list":[
            {
                "alarmId":"xxxx",
                "firstAlarmType":1,
                "alarmType":1,
                "startTime":1600653494,
                "endTime":1600653495,
                "imgUrlSuffix":"xxxxx"
            }
        ],
        "validStartTime":1111,
        "pageEnd":false
    }
}

// 图片下载地址为 imgUrl = imgUrlPrefix + imgUrlSuffix
// 缩略图下载地址为 thumbUrl = imgUrl + thumbUrlSuffix
```
对应 json 结构：

参数名称      |类型    |描述
--------------|--------|-----
alarmId       |string  |事件id
firstAlarmType|int64   |告警触发时的告警类型
alarmType     |int64   |告警有效时间内触发过的告警类型
startTime     |int64   |告警触发时间, utc时间，单位秒
endTime       |int64   |告警结束时间, utc时间，单位秒
imgUrlPrefix  |string  |告警图片下载地址前缀缀
imgUrlSuffix  |string  |告警图片下载地址后缀
thumbUrlSuffix|string  |告警图片缩略图下载地址后缀
validVideoStartTime|int64|云存未过期视频的开始时间，为0代表未查询到云存记录
pageEnd|bool| 为分页结束标志

### 6. 事件删除
```swift
/// 事件删除
/// @param deviceId 设备id
/// @param eventIds 事件 id 数组
/// @param responseHandler 回调
open func deleteEvents(withDeviceId deviceId: String, eventIds: [String], responseHandler: IVNetworkResponseHandler? = nil)
```

具体使用示例请参考：demo 内`IJKMediaViewController.swift`

# 错误码

## 公共错误码

| 错误码区间分布 | 错误描述           |
| :------------: | ------------------ |
|  8000 - 8499   | Asrv错误           |
|  8500 - 8699   | Csrv错误(对接Asrv) |
|  8799 - 9999   | 预留错误           |
| 10000 - 10999  | 通用错误           |
| 11000 - 11999  | 产品/设备相关错误   |
| 12000 - 12999  | 用户相关错误       |
| 13000 - 13999  | 客户相关错误       |
| 14000 - 14999  | 云存相关错误       |
| 15000 - 15999  | UPG相关错误        |
| 16000 - 16999  | 帮助中心错误       |
| 17000 - 17999  | 第三方调用错误     |
| 20000 - 20150  | P2P错误part1      |
| 20151 - 20199  | 客户自定义错误      |
| 20200 - 20999  | P2P错误part2     |
| 21000 - 21999  | iOS SDK错误        |
| 22000 - 22999  | Android SDK错误    |
| 23000 - 23999  | PC SDK错误         |
| 24000 - 24999  | DEV SDK错误        |

## 常见服务器错误码

| ASrvErr                                | 错误码 | 错误描述                         |
| :------------------------------------- | :----: | -------------------------------- |
| IVASrvErr_dst_offline                  |  8000  | 目标离线                         |
| IVASrvErr_dst_notexsit                 |  8002  | 目标不存在                       |
| IVASrvErr_dst_error_relation           |  8003  | 非法关系链                       |
| IVASrvErr_binderror_dev_usr_has_bind   |  8022  | 设备已经绑定此用户               |
| IVASrvErr_binderror_dev_has_bind_other |  8023  | 设备已经绑定其他用户             |
| IVASrvErr_binderror_customer_diffrent  |  8024  | 设备的客户ID与用户的客户ID不一致 |

## P2P错误码

| TermErr | 错误码 | 错误描述 |
| :------ | :----: | -------- |
| IVTermErr_msg_send_peer_timeout          				| 20001 |  消息发送给对方超时 |
| IVTermErr_msg_calling_dev_hangup         				| 20002 |  普通挂断，即设备端主动断开，APP可尝试重连 |
| IVTermErr_msg_calling_send_timeout       				| 20003 |  calling消息发送超时 |
| IVTermErr_msg_calling_no_srv_addr        				| 20004 |  服务器未分配转发地址，APP可尝试重连 |
| IVTermErr_msg_calling_handshake_timeout  				| 20005 |  握手超时，APP可尝试重连 |
| IVTermErr_msg_calling_token_error        				| 20006 |  设备端token校验失败 |
| IVTermErr_msg_calling_all_chn_busy       				| 20007 |  监控通道数满 |
| IVTermErr_msg_calling_timeout_disconnect 				| 20008 |  超时断开，APP可尝试重连 |
| IVTermErr_msg_calling_no_find_dst_id     				| 20009 |  未找到目的id |
| IVTermErr_msg_calling_check_token_error  				| 20010 |  token校验出错 |
| IVTermErr_msg_calling_dev_is_disable     				| 20011 |  设备已经禁用 |
| IVTermErr_msg_calling_duplicate_call     				| 20012 |  重复呼叫 |
| IVTermErr_msg_calling_caller_hungup      				| 20013 |  连接过程中主动断开 |
| IVTermErr_msg_calling_relation_modify    				| 20014 |  关系链变更导致的断开 |
| IVTermErr_msg_access_lib_not_init        				| 20015 |  接入库未初始化 |
| IVTermErr_msg_lan_calling_not_allow      				| 20016 |  纯局域网下密码错误或者未进行密码校验 |
| IVTermErr_msg_calling_no_relation        				| 20017 |  APP与设备不存在关系链 |
| IVTermErr_msg_calling_no_online          				| 20018 |  APP还没上线，稍后再试 |
| IVTermErr_msg_gdm_handle_processing       			| 20100 |  设备正在处理中 |
| IVTermErr_msg_gdm_handle_leaf_path_error  			| 20101 |  设备端校验叶子路径非法 |
| IVTermErr_msg_gdm_handle_parse_json_fail  			| 20102 |  设备端解析JSON出错 |
| IVTermErr_msg_gdm_handle_fail             			| 20103 |  设备处理ACtion失败 |
| IVTermErr_msg_gdm_handle_no_cb_registered 			| 20104 |  设备未注册相应的ACtion回调函数 |
| IVTermErr_msg_gdm_handle_buildin_prowritable_error 	| 20105 |  设备不允许通过局域网修改内置可写对象 |
| IVTermErr_msg_saas_hungup_code_invalid    			| 20135 |  设备saas层挂断但是错误码给的超过范围 |
| IVTermErr_msg_wait_option_timeout_hangup  			| 20136 |  下载文件过程中，设备SDK等待新的操作超时导致挂断 |
| IVTermErr_msg_find_record_file_fail       			| 20137 |  查找指定的回放文件失败导致播放失败，存储介质被移除、录像文件不存在，无法打开 |
| IVTermErr_msg_read_record_file_fail       			| 20138 |  读取指定的回放文件失败导致播放失败, 中途被移除、无视频帧文件不合法、不可读、内存申请失败 |
| IVTermErr_msg_user_cmd_internal_error     			| 20140 |  设备端内部处理错误 |
| IVTermErr_msg_user_cmd_type_error         			| 20141 |  不支持的 user cmd 类型 |
| IVTermErr_msg_user_cmd_version_error      			| 20142 |  不支持的 user cmd 版本 |
| IVTermErr_msg_user_cmd_param_error        			| 20143 |  user cmd 参数超出范围 |
| IVTermErr_msg_user_cmd_option_mismatch    			| 20145 |  操作和状态不匹配，比如对讲已经开启但是又开启 |
| IVTermErr_msg_user_cmd_saas_err_invalid   			| 20146 |  saas层返回的错误码超过范围 |

## 消息管理错误码

| IVMessageError                  | 错误码 | 错误描述                        |
| :------------------------------ | :----: | ------------------------------- |
| IVMessageError_duplicate        | 21000  | 消息重复/正在发送               |
| IVMessageError_sendFailed       | 21001  | 消息发送失败                    |
| IVMessageError_timeout          | 21002  | 消息响应超时                    |
| IVMessageError_GetGdmDataErr    | 21003  | 获取物模型失败                  |
| IVMessageError_RcvGdmDataErr    | 21004  | 接收物模型失败                  |
| IVMessageError_SendPassSrvErr   | 21005  | 透传数据给服务器失败            |
| IVMessageError_SendPassDevErr   | 21006  | 透传数据给设备失败              |
| IVMessageError_NotFoundCallback | 21007  | 没有找到回调/已超时             |
| IVMessageError_ExceedsMaxLength | 21008  | 消息长度超出上限(MAX_DATA_SIZE) |

## 连接错误码

| IVConnError                  | 错误码 | 错误描述                             |
| :--------------------------- | :----: | ------------------------------------ |
| IVConnError_ExceedsMaxNumber | 21020  | 连接通道已达上限(MAX_CONNECTION_NUM) |
| IVConnError_Duplicate        | 21021  | 连接通道已存在                       |
| IVConnError_ConnectFailed    | 21022  | 建立连接失败                         |
| IVConnError_Disconnected     | 21023  | 连接已断开/未连接                    |
| IVConnError_ExceedsMaxLength | 21024  | 数据长度超出上限(MAX_PKG_BYTES)      |
| IVConnError_NotAvailableNow  | 21025  | 当前连接暂不可用/SDK离线             |
| IVConnError_SendDataFailed   | 21026  | 发送用户数据失败                     |

## 播放器错误码

| IVPlayerError                         | 错误码 | 错误描述                         |
| :------------------------------------ | :----: | -------------------------------- |
| IVPlayerError_NoRespondsToSelector    | 21030  | 方法选择器无响应、未实现协议方法 |
| IVPlayerError_InvalidParameter        | 21031  | 参数错误                         |
| IVPlayerError_PlaybackListEmpty       | 21032  | 录像列表为空                     |
| IVPlayerError_PlaybackDataErr         | 21033  | 录像列表数据异常                 |
| IVPlayerError_RecorderIsRunning       | 21034  | 正在录制                         |
| IVPlayerError_VideoResolutionChanged  | 21035  | 视频分辨率已改变                 |
| IVPlayerError_EncoderNotAvailableNow  | 21036  | 编码器暂不可用                   |
| IVPlayerError_PlaybackListVerErr      | 21037  | 不支持的录像列表版本             |
| IVPlayerError_DeviceOperationFailed   | 21038  | 设备端操作失败                   |
| IVPlayerError_RecorderNotAvailableNow | 21039  | 录制器暂不可用                   |
| IVPlayerError_OperationNotAllowedNow  | 21040  | 当前状态下不允许该操作           |
| IVPlayerError_AVInformationAbnormal   | 21041  | 音视频信息相关参数异常           |

## 下载错误码

| IVDownloadError                  | 错误码 | 错误描述                                                 |
| :------------------------------- | :----: | -------------------------------------------------------- |
| IVDownloadError_DownloaderBusy   | 21060  | 下载器正忙，若要下载其他文件，请先暂停当前任务           |
| IVDownloadError_FileUnavailable  | 21061  | 文件读取失败，文件被删除、存储设备拔出                   |
| IVDownloadError_IncorrectOffset  | 21062  | 断点续传offset大于文件大小fileSize                       |
| IVDownloadError_FileOpenFailed   | 21063  | 打开文件失败，文件权限、文件被删除、存储设备拔出         |
| IVDownloadError_FileNotFound     | 21064  | 找不到文件，文件被删除，存储设备拔出                     |
| IVDownloadError_ProcessExited    | 21065  | 设备程序/模块退出、无法继续传输                          |
| IVDownloadError_DataSizeAbnormal | 21070  | 接收的数据大小不等于文件总大小                           |
| IVDownloadError_DevUnknownError  | 21071  | 设备端发生未知错误                                       |
| IVDownloadError_DevNoResponse    | 21072  | 设备端无响应（如固件版本未支持下载，网络故障、程序故障） |

## 设备端ACK错误

| IVAckErr              | 错误码 | 错误描述                                           |
| :-------------------- | :----: | :------------------------------------------------- |
| IVAckErr_NotSupport   | 21080  | 设备端不支持该命令                                 |
| IVAckErr_ParameterErr | 21081  | 设备端判定参数错误                                 |
| IVAckErr_UnknownErr   | 21082  | 设备端发生未知错误                                 |
| IVAckErr_NoResponse   | 21083  | 设备端无响应(如固件版本未支持，网络故障、程序故障) |
| IVAckErr_DeviceBusy   | 21084  | 设备端正在处理指令，不接受新的指令                 |

## 配网错误码

| IVNetCfgErr              | 错误码 | 错误描述         |
| ------------------------ | :----: | ---------------- |
| IVNetCfgErr_GetTokenErr  | 21100  | 获取Token失败    |
| IVNetCfgErr_TokenExpired | 21101  | Token已过期      |
| IVNetCfgErr_DevStatusErr | 21102  | 设备非可绑定状态 |
| IVNetCfgErr_ServerErr    | 21103  | 服务器报错       |

