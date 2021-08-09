# 常见问题Q&A

#### 日志相关提示
- 提示1：为方便定位问题，开发阶段建议启用SDK日志输出，设置方法参考 `《IoTVideo-iOS开发指南》->【快速开始】->【第三步：SDK初始化】->【1、初始化】`
- 提示2：日志中形如 {…17} 表示此位置包含了17次同类型日志信息。例如：`11:09:46.995 [SDK] {...17} CH1 vi_rcv pts:1050000 (+50000) len:1355`表示最近收到了17个音频数据包，并且最后一次具体数据为`pts:1050000 (+50000) len:1355`

#### 如何查看SDK版本信息

- 方法一：日志输出
```
10:47:15.981 [SDK] [I]💙 > sdk-version:       1.4(2074) Debug  
10:47:15.981 [SDK] [I]💙 > compile-date:      2021-07-09 10:46:45  
```

- 方法二：头文件IoTVideo.h
```
#define kIoTVideoVersion "1.4(2074) Debug" /* Commit:bee5eaa */
#define kIoTVideoCompileDate "2021-07-09 10:46:45"
```

#### 一、SDK环境异常

##### 1. 如何判断APP网络是否正常？
```
日志输出: 
15:52:17.714 [SDK] [I]💙 ====当前网络状态为WiFi(IV-TEST-5G)=======

日志解读: 
当前手机连接了名为 “IV-TEST-5G”的Wi-Fi网络, 请确认该网络可正常上网
```

##### 2. 如何判断SDK是否可以正常使用？
```
日志输出：
15:52:17.999 [SDK] [I]💙 IoTVideoSDK 🟩SDK在线(1)

日志解读：
收到`IoTVideo.linkStatus`更新通知
    - 在线：可正常使用
    - 离线：请检查网络，或尝试注册SDK
    - Token失败：尝试重新注册SDK
    - 账号被踢飞：尝试重新注册SDK

提示：可通过`-[IoTVideo linkStatus]`主动查询，也可通过`-[IoTVideoDelegate didUpdateLinkStatus:]`监听
```

##### 3. 如何判断设备是否在线？
```
日志输出：
15:55:28.599 [SDK] [I]💙 rcv_gdm_data_callback msgid:0 tid:031400005f9f7056a605e40150f1e0ac type:2 path:ProReadonly._online json:{"stVal":1,"t":1626162928} ok

日志解读：
收到`ProReadonly._online`更新通知
    - stVal:0 离线
    - stVal:1 在线
    - stVal:2 休眠

提示：也可通过`-[IVMessageMgr readPropertyOfDevice:path:completionHandler:]`主动查询（path取"ProReadonly._online"）
```

#### 二、 监控异常
*提示1: 为快速定位监控相关问题，请知悉播放器的四大阶段及对应步骤的日志信息。如下所示：*
*提示2: `*au*`为音频相关，`*vi*`为视频相关*
*提示3: pts单位为微秒，由设备端在回调函数中填入，在APP端可见步骤⑦⑧⑨中的pts字段*
*提示4: SDK提供保存关键步骤的音视频数据到沙盒的功能，便于校验数据正确性，默认关闭，详见`+[IVPlayer debugMode]`*

(1) 连接阶段：
```
①创建播放器
15:56:04.562 [SDK] IVMonitorPlayer(0x157d96850) init 031400005f9f7056a605e40150f1e0ac_0:1
...
②建立连接
15:56:04.599 [SDK] IVMonitorPlayer(0x157d96850) async play
15:56:04.599 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH-1 status=Preparing...
15:56:04.599 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH-1 connStatus=Connecting...
...
③连接成功
15:56:05.019 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 connStatus=Connected
15:56:05.019 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 status=Ready
15:56:05.025 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 status=Loading...
```

(2) 初始化阶段：
```
④收到音视频信息头
15:56:05.074 [SDK] [I]💙 CH2 rcv AVHeader at:4 am:0 ac:2 abw:16 ar:8000 aspf:1024 vt:1 vr:20 vw:640 vh:360
15:56:05.074 [SDK] [I]💙 CH2 media-streams: Audio + Video
...
⑤注册编/解码器
15:56:05.110 [SDK] [I]💙 CH2 adec:aac register ch:1 ar:8000
15:56:05.139 [SDK] [I]💙 CH2 aenc:aac register ch:1 ar:8000
15:56:05.143 [SDK] [I]💙 CH2 vdec:h264 register
...
⑥启动音视频渲染器
15:56:05.075 [SDK] [I]💙 CH2 start_au_render
15:56:05.079 [SDK] [I]💙 CH2 start_vi_render W640xH360
```

(3) 解码渲染阶段：
```
⑦收到音视频数据包
15:56:05.145 [SDK] CH2 vi_rcv pts:0 (+0) len:5751
15:56:05.190 [SDK] CH2 au_rcv pts:128000 (+128000) len:214
...
15:56:06.174 [SDK] {...22} CH2 vi_rcv pts:1100000 (+50000) len:1343
15:56:06.325 [SDK] {...9} CH2 au_rcv pts:1280000 (+128000) len:162
...
⑧解码数据包
15:56:05.185 [SDK] CH2 vi_dec i:0x11004c000(5751) o:0x15803daf8->0x15803daf8(1476647696) pts:0
15:56:05.192 [SDK] CH2 au_dec i:0x158233a00(214) o:0x10f0b8000(20480) pts:128000
...
15:56:06.215 [SDK] {...23} CH2 vi_dec i:0x110bcc000(1254) o:0x15803dc64->0x15803dc64(1476648060) pts:1150000
15:56:06.331 [SDK] {...9} CH2 au_dec i:0x15824a200(162) o:0x10f0c0000(20480) pts:1280000
...
⑨渲染音视频帧
15:56:05.138 [SDK] {...9} CH2 vi_ren no frame
15:56:05.209 [SDK] CH2 vi_ren pts:0 (+0) remain:+150000
15:56:06.267 [SDK] {...21} CH2 vi_ren pts:1050000 (+50000) remain:+150000
15:56:06.267 [SDK] {...21} CH2 vi_ren wait vpts(1050000)-apts(0)=+1050000
...
15:56:05.410 [SDK] {...20} CH2 au_ren no frame
15:56:05.522 [SDK] CH2 au_ren pts:138750 (+138750) remain:+245250 size:172
15:56:06.524 [SDK] {...94} CH2 au_ren pts:1333375 (+10625) remain:+74625 size:170
```

(4) 断开阶段：
```
⑩断开连接
15:56:25.386 [SDK] IVMonitorPlayer(0x157d96850) CH2 sync stop
15:56:25.386 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 status=Stopping...
15:56:25.386 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 connStatus=Disconnecting...
...
⑪关闭编解码器
15:56:25.393 [SDK] CH2 aenc:aac unregister
15:56:25.393 [SDK] CH2 aenc:aac dealloc
15:56:25.404 [SDK] CH2 adec:aac unregister
15:56:25.404 [SDK] CH2 adec:aac dealloc
15:56:25.404 [SDK] CH2 vdec:h264 unregister
15:56:25.404 [SDK] CH2 vdec:h264 dealloc
... 
⑫关闭渲染器
15:56:25.386 [SDK] CH2 stop_au_render
12:14:31.179 [SDK] CH2 stop_vi_render 
...
⑬释放播放器
15:56:25.415 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 connStatus=Disconnected
15:56:25.416 [SDK] [I]💙 IVMonitorPlayer(0x157d96850) CH2 status=Stopped
15:56:25.420 [SDK] IVMonitorPlayer(0x157d96850) dealloc
15:56:25.420 [SDK] CH2 IVAudioUnit dealloc
15:56:25.420 [SDK] CH2 IVAVRecorder dealloc
15:56:25.421 [SDK] CH2 IVVideoRender did dealloc
```

**Q：监控不出图？无声音？**

请按顺序搜索步骤①～⑨中日志信息的关键字，确认APP处于流程中哪个步骤：
```
1. 若①～③过程未完成，属于连接未成功：
    1）设备网络不通，需切换设备网络；
    2）手机网络不通，需切换手机网络；
    3）设备无响应，需排查设备日志（常见任务超时、任务阻塞、死循环、设备离线）；
2. 若步骤④未完成，请检查设备是否有发送该音视频信息头；
3. 若⑤～⑥未完成，请确认步骤④中设备传给APP的音视频信息头无误，否则会导致步骤⑤解码器和步骤⑥渲染器初始化错误；
4. 若⑦～⑨过程无日志或未持续输出日志，请确认设备是否未发送数据或已停止发送数据；
5. 请确保正确设置IVPlayer.videoView的约束；
6. 其他情况请保留完整APP日志和设备日志，并联系我们；
```

**Q: 监控出图慢？**

请按以下顺序排查问题：
```
1. 若①～③过程耗时大于1秒，属于连接慢：
    1）设备网络慢，需切换设备网络；
    2）手机网络慢，需切换手机网络；
    3）设备响应慢，需排查设备日志（常见CPU负载高、任务阻塞）；
2. 若③～⑦过程耗时大于1秒，属于收到数据慢：
    1）设备网络不稳定，可尝试切换设备网络；
    2）手机网络不稳定，可尝试切换手机网络；
    3）设备响应慢，需排查设备日志（常见编码慢、回调慢、CPU负载高、任务阻塞）
3. 若⑦～⑨过程耗时大于1秒，属于解码渲染慢：
    1）请确认步骤④中设备传给APP的音视频信息头无误，否则会导致步骤⑤解码器和步骤⑥渲染器初始化错误
    2）请确认设备发送的数据是可播放的（发送前记录到本地，用vlc或ffplay等验证）
    3）请确认步骤⑦收到的音视频数据包与设备端发送的一致，否则应该是数据丢包了 
    4）请确认音视频帧pts正确，且同一时间音视频pts不能相差超过1秒，否则会导致音视频同步异常，进而导致步骤⑨渲染异常, 
    5）请确认APP解码成功，如上面步骤⑧的日志
4. 其他情况请保留完整APP日志和设备日志，并联系我们。
```

**Q: 监控延迟大？卡顿？**

请按以下思路排查问题：
```
1. 请检查网络是否流畅；
2. 请确认音视频帧pts正确，且同一时间音视频pts不能相差超过1秒，否则会导致音视频同步异常，进而导致步骤⑨渲染异常；
3. 查看步骤⑦的音视频pts是否连续，若不连续则表明有丢包，需检查设备发送情况和网络环境；
4. 日志搜索"jitter stalled"可查看网络抖动情况。其中"tolerance"越大表明网络抖动越厉害，"delay"也会越大，若频繁输出此信息，表明网络不佳, 可尝试切换手机或设备网络；
5. 从APP端日志估算⑦～⑨解码渲染阶段耗时，以上面的日志为例：
    注意：并非每个数据包都会输出日志，估算时可认为相近的pts是同一个数据包，例如839123456和839000000是相近的，因为他们仅相差0.123456秒

    15:56:50.227 收到了 pts为839000000 的视频包
    15:56:50.272 解码出 pts为839000000 的视频帧
    15:56:50.311 将渲染 pts为839000000 的视频帧

    耗时为 15:56:50.311 - 15:56:50.227 ≈ 0.084秒，记为Td

    1) 若Td一直很小，表明APP端处理基本不耗时，延时原因可能出在网络或者设备编码速度上；
    2) 若Td较大或忽大忽小：表明网络不佳，可尝试切换手机或设备网络；
```

**Q: 音视频不同步**
```
请确认音视频帧pts正确，且同一时间音视频pts不能相差超过1秒，否则会导致音视频同步异常，进而导致步骤⑨渲染异常；
```

**Q: 为什么seek不精准**

```
1. 设备端SDKv1.3.xxxx及之前的版本
    seek精度由设备端的GOP决定，比如GOP是4秒的话精度就是4秒。
    因为解码器是需要参考I帧的，设备会优先找seek时间点之后的最近一个I帧开始播放，保证解码器可以解码，因此不可能精确到秒。
    比如I帧分布在 0 4 8 12 16 秒的位置，如果seek到6秒位置，因为给APP发6秒位置开始的数据APP也解码不了，所以设备是会从8秒位置的I帧开始发送数据的。
2. 设备端SDKv1.4.xxxx及之后的版本
    在上述策略基础上优化搜索I帧方式，取距离seek位置最近的一个I帧，误差为1/2个GOP时间，GOP为4秒的话精度就是2秒。
```

